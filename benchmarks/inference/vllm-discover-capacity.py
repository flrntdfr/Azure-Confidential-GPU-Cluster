#!/usr/bin/env python3
"""
Capacity Discovery for vLLM Inference Servers

Performs a geometric sweep of request rate (λ) to find the capacity knee for a given
model and input/output token configuration. Uses open-loop benchmarking to determine
optimal operating points for both TEE-OFF and TEE-ON experiments.

Stop conditions:
    S1: P99 latency > SLA_P99_MS
    S2: Achieved_QPS / Requested_QPS < ACHIEVED_RATIO_MIN AND P95 jumps ≥ P95_JUMP_FRAC
"""

import argparse
import json
import logging
import re
import subprocess
import sys
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path
from typing import Optional, List, Dict, Any


@dataclass
class BenchmarkMetrics:
    """Metrics from a single benchmark run."""
    requested_qps: float
    achieved_qps: float
    ratio: float
    p50_ms: float
    p95_ms: float
    p99_ms: float
    mean_ttft_ms: float = 0.0
    median_ttft_ms: float = 0.0
    p99_ttft_ms: float = 0.0
    mean_tpot_ms: float = 0.0
    median_tpot_ms: float = 0.0
    p99_tpot_ms: float = 0.0
    throughput_toks: float = 0.0


@dataclass
class CapacityResult:
    """Final capacity discovery results."""
    model: str
    tokenizer: str
    input_tokens: int
    output_tokens: int
    capacity_qps: float
    targets: Dict[str, float]  # 50%, 70%, 90%, 105%
    discovery_steps: List[Dict[str, Any]]
    parameters: Dict[str, Any]
    timestamp: str


class VLLMBenchmarkParser:
    """Parses vLLM benchmark output to extract metrics."""
    
    # Regex patterns for common vLLM bench serve output formats
    PATTERNS = {
        'p50': [
            r'p50\s+latency[:\s]+([0-9.]+)\s*ms',
            r'median.*?latency[:\s]+([0-9.]+)',
            r'50th.*?percentile[:\s]+([0-9.]+)',
        ],
        'p95': [
            r'p95\s+latency[:\s]+([0-9.]+)\s*ms',
            r'95th.*?percentile[:\s]+([0-9.]+)',
        ],
        'p99': [
            r'p99\s+latency[:\s]+([0-9.]+)\s*ms',
            r'99th.*?percentile[:\s]+([0-9.]+)',
        ],
        'achieved_qps': [
            r'achieved.*?qps[:\s]+([0-9.]+)',
            r'actual.*?qps[:\s]+([0-9.]+)',
            r'throughput[:\s]+([0-9.]+)\s+requests',
        ],
        'mean_ttft': [
            r'mean\s+ttft[:\s]+([0-9.]+)',
            r'avg.*?ttft[:\s]+([0-9.]+)',
        ],
        'median_ttft': [
            r'median\s+ttft[:\s]+([0-9.]+)',
            r'p50.*?ttft[:\s]+([0-9.]+)',
        ],
        'p99_ttft': [
            r'p99\s+ttft[:\s]+([0-9.]+)',
        ],
        'mean_tpot': [
            r'mean\s+tpot[:\s]+([0-9.]+)',
            r'avg.*?tpot[:\s]+([0-9.]+)',
        ],
        'median_tpot': [
            r'median\s+tpot[:\s]+([0-9.]+)',
            r'p50.*?tpot[:\s]+([0-9.]+)',
        ],
        'p99_tpot': [
            r'p99\s+tpot[:\s]+([0-9.]+)',
        ],
        'throughput': [
            r'throughput[:\s]+([0-9.]+)\s+tokens',
            r'tokens.*?per.*?second[:\s]+([0-9.]+)',
        ],
    }
    
    @classmethod
    def parse(cls, output: str) -> Dict[str, float]:
        """Parse benchmark output and extract all available metrics."""
        metrics = {}
        
        for metric_name, patterns in cls.PATTERNS.items():
            for pattern in patterns:
                match = re.search(pattern, output, re.IGNORECASE | re.MULTILINE)
                if match:
                    try:
                        metrics[metric_name] = float(match.group(1))
                        break
                    except (ValueError, IndexError):
                        continue
        
        return metrics


class CapacityDiscovery:
    """Discovers server capacity through geometric sweep of request rates."""
    
    def __init__(
        self,
        model: str,
        tokenizer: str,
        base_url: str = "http://127.0.0.1:8000",
        endpoint: str = "/v1/chat/completions",
        input_tokens: int = 256,
        output_tokens: int = 128,
        lambda_start: float = 10.0,
        multiplier: float = 1.25,
        max_steps: int = 12,
        duration_s: int = 180,
        warmup_s: int = 30,
        max_concurrency: int = 512,
        sla_p99_ms: float = 2000.0,
        achieved_ratio_min: float = 0.90,
        p95_jump_frac: float = 0.30,
        log_dir: Path = Path("/persistent/logs/vllm"),
        verbose: bool = False,
    ):
        self.model = model
        self.tokenizer = tokenizer
        self.base_url = base_url
        self.endpoint = endpoint
        self.input_tokens = input_tokens
        self.output_tokens = output_tokens
        self.lambda_start = lambda_start
        self.multiplier = multiplier
        self.max_steps = max_steps
        self.duration_s = duration_s
        self.warmup_s = warmup_s
        self.max_concurrency = max_concurrency
        self.sla_p99_ms = sla_p99_ms
        self.achieved_ratio_min = achieved_ratio_min
        self.p95_jump_frac = p95_jump_frac
        self.log_dir = Path(log_dir)
        self.verbose = verbose
        
        # Setup logging
        log_level = logging.DEBUG if verbose else logging.INFO
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s [%(levelname)s] %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        self.logger = logging.getLogger(__name__)
        
        # Create log directory
        self.log_dir.mkdir(parents=True, exist_ok=True)
        
        # Run metadata
        self.timestamp = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
        self.run_tag = f"DISCOVER_{model.replace('/', '_')}_{input_tokens}x{output_tokens}_{self.timestamp}"
        
        # Results tracking
        self.discovery_steps: List[Dict[str, Any]] = []
        
    def run_benchmark(self, request_rate: int, step: int) -> Optional[BenchmarkMetrics]:
        """
        Run a single benchmark at the specified request rate.
        
        Args:
            request_rate: Target QPS (requests per second)
            step: Step number for logging
            
        Returns:
            BenchmarkMetrics if successful, None otherwise
        """
        log_file = self.log_dir / f"{self.run_tag}_L{request_rate}.log"
        
        self.logger.info(
            f"[Step {step}] Running benchmark at λ={request_rate} rps "
            f"(duration={self.duration_s}s, warmup={self.warmup_s}s)"
        )
        self.logger.info(f"Log file: {log_file}")
        
        # Build vllm bench command
        cmd = [
            "vllm", "bench", "serve",
            "--backend", "vllm",
            "--base-url", self.base_url,
            "--endpoint", self.endpoint,
            "--model", self.model,
            "--tokenizer", self.tokenizer,
            "--dataset-name", "random",
            "--random-input-len", str(self.input_tokens),
            "--random-output-len", str(self.output_tokens),
            "--request-rate", str(request_rate),
            "--poisson",
            "--duration", str(self.duration_s),
            "--warmup", str(self.warmup_s),
            "--max-concurrency", str(self.max_concurrency),
            "--temperature", "0",
            "--timeout", "600",
        ]
        
        try:
            # Run benchmark and capture output
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=self.duration_s + self.warmup_s + 120,  # Extra buffer
            )
            
            # Write output to log file
            with open(log_file, 'w') as f:
                f.write(result.stdout)
                if result.stderr:
                    f.write("\n=== STDERR ===\n")
                    f.write(result.stderr)
            
            # Parse metrics
            parsed = VLLMBenchmarkParser.parse(result.stdout)
            
            if not parsed:
                self.logger.warning("No metrics parsed from benchmark output")
                return None
            
            # Build metrics object with defaults
            metrics = BenchmarkMetrics(
                requested_qps=float(request_rate),
                achieved_qps=parsed.get('achieved_qps', 0.0),
                ratio=parsed.get('achieved_qps', 0.0) / request_rate if request_rate > 0 else 0.0,
                p50_ms=parsed.get('p50', 0.0),
                p95_ms=parsed.get('p95', 0.0),
                p99_ms=parsed.get('p99', 0.0),
                mean_ttft_ms=parsed.get('mean_ttft', 0.0),
                median_ttft_ms=parsed.get('median_ttft', 0.0),
                p99_ttft_ms=parsed.get('p99_ttft', 0.0),
                mean_tpot_ms=parsed.get('mean_tpot', 0.0),
                median_tpot_ms=parsed.get('median_tpot', 0.0),
                p99_tpot_ms=parsed.get('p99_tpot', 0.0),
                throughput_toks=parsed.get('throughput', 0.0),
            )
            
            self.logger.info(
                f"Metrics: P95={metrics.p95_ms:.1f}ms, P99={metrics.p99_ms:.1f}ms, "
                f"achieved_qps={metrics.achieved_qps:.2f}, ratio={metrics.ratio:.3f}"
            )
            
            return metrics
            
        except subprocess.TimeoutExpired:
            self.logger.error(f"Benchmark timed out at λ={request_rate}")
            return None
        except Exception as e:
            self.logger.error(f"Benchmark failed at λ={request_rate}: {e}")
            return None
    
    def check_stop_conditions(
        self,
        metrics: BenchmarkMetrics,
        prev_p95: Optional[float],
        step: int,
    ) -> tuple[bool, str]:
        """
        Check if any stop condition is met.
        
        Returns:
            (should_stop, reason)
        """
        # S1: P99 exceeds SLA
        if metrics.p99_ms > self.sla_p99_ms:
            return True, f"S1: P99={metrics.p99_ms:.1f}ms > SLA={self.sla_p99_ms}ms"
        
        # S2: Low achievement ratio AND significant P95 jump
        if metrics.ratio < self.achieved_ratio_min:
            if prev_p95 is not None and prev_p95 > 0:
                p95_jump = (metrics.p95_ms - prev_p95) / prev_p95
                self.logger.info(f"P95 jump vs previous: {p95_jump:.3f} ({p95_jump*100:.1f}%)")
                
                if p95_jump >= self.p95_jump_frac:
                    return True, (
                        f"S2: ratio={metrics.ratio:.3f} < {self.achieved_ratio_min} "
                        f"AND P95 jumped {p95_jump*100:.1f}% (threshold: {self.p95_jump_frac*100:.1f}%)"
                    )
            else:
                self.logger.info("No previous P95; cannot evaluate jump yet")
        
        return False, ""
    
    def discover(self) -> CapacityResult:
        """
        Run the capacity discovery sweep.
        
        Returns:
            CapacityResult with discovered capacity and recommended targets
        """
        self.logger.info(f"Starting capacity discovery for {self.model}")
        self.logger.info(f"Workload: {self.input_tokens} input / {self.output_tokens} output tokens")
        self.logger.info(f"Stop conditions: SLA_P99={self.sla_p99_ms}ms, "
                        f"ratio_min={self.achieved_ratio_min}, "
                        f"P95_jump={self.p95_jump_frac}")
        self.logger.info("")
        
        current_lambda = self.lambda_start
        prev_p95: Optional[float] = None
        capacity_qps: Optional[float] = None
        
        for step in range(1, self.max_steps + 1):
            request_rate = round(current_lambda)
            if request_rate < 1:
                request_rate = 1
            
            # Run benchmark
            metrics = self.run_benchmark(request_rate, step)
            
            if metrics is None:
                self.logger.warning(f"Step {step} failed, using previous capacity")
                break
            
            # Record step
            step_data = {
                'step': step,
                'lambda_rps': request_rate,
                'metrics': asdict(metrics),
            }
            self.discovery_steps.append(step_data)
            
            # Check stop conditions
            should_stop, reason = self.check_stop_conditions(metrics, prev_p95, step)
            
            if should_stop:
                self.logger.info(f"Stop condition met: {reason}")
                
                # Capacity is the last stable lambda (previous step)
                if step > 1:
                    capacity_qps = round(current_lambda / self.multiplier)
                else:
                    # Stopped at first point - use it conservatively
                    capacity_qps = float(request_rate)
                
                step_data['stopped'] = True
                step_data['stop_reason'] = reason
                break
            
            # Continue to next step
            prev_p95 = metrics.p95_ms
            current_lambda *= self.multiplier
        
        # If loop finished without stopping, use last tested value
        if capacity_qps is None:
            capacity_qps = float(request_rate)
            self.logger.info("Completed all steps without hitting stop condition")
        
        self.logger.info("")
        self.logger.info(f"Discovered capacity (λ*): {capacity_qps:.1f} rps")
        
        # Calculate target loads
        targets = {
            '50%': round(capacity_qps * 0.50),
            '70%': round(capacity_qps * 0.70),
            '90%': round(capacity_qps * 0.90),
            '105%': round(capacity_qps * 1.05),
        }
        
        self.logger.info("Recommended targets for experiments (use for both NC and NCC):")
        for pct, qps in targets.items():
            self.logger.info(f"  {pct:>4}: {qps:>5.0f} rps")
        
        # Build final result
        result = CapacityResult(
            model=self.model,
            tokenizer=self.tokenizer,
            input_tokens=self.input_tokens,
            output_tokens=self.output_tokens,
            capacity_qps=capacity_qps,
            targets=targets,
            discovery_steps=self.discovery_steps,
            parameters={
                'lambda_start': self.lambda_start,
                'multiplier': self.multiplier,
                'duration_s': self.duration_s,
                'warmup_s': self.warmup_s,
                'max_steps': self.max_steps,
                'sla_p99_ms': self.sla_p99_ms,
                'achieved_ratio_min': self.achieved_ratio_min,
                'p95_jump_frac': self.p95_jump_frac,
                'max_concurrency': self.max_concurrency,
            },
            timestamp=self.timestamp,
        )
        
        return result
    
    def save_results(self, result: CapacityResult) -> Path:
        """Save results to JSON file."""
        output_file = self.log_dir / f"{self.run_tag}_summary.json"
        
        with open(output_file, 'w') as f:
            json.dump(asdict(result), f, indent=2)
        
        self.logger.info(f"Results saved to: {output_file}")
        return output_file


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Discover vLLM server capacity through geometric QPS sweep",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    
    # Server configuration
    parser.add_argument(
        '--model',
        type=str,
        required=True,
        help='Model identifier (alias on server)',
    )
    parser.add_argument(
        '--tokenizer',
        type=str,
        required=True,
        help='Tokenizer identifier (e.g., meta-llama/Llama-3.1-8B-Instruct)',
    )
    parser.add_argument(
        '--base-url',
        type=str,
        default='http://127.0.0.1:8000',
        help='vLLM server base URL',
    )
    parser.add_argument(
        '--endpoint',
        type=str,
        default='/v1/chat/completions',
        help='API endpoint path',
    )
    
    # Workload configuration
    parser.add_argument(
        '--input-tokens',
        type=int,
        default=256,
        help='Input sequence length in tokens',
    )
    parser.add_argument(
        '--output-tokens',
        type=int,
        default=128,
        help='Output sequence length in tokens',
    )
    
    # Sweep configuration
    parser.add_argument(
        '--lambda-start',
        type=float,
        default=10.0,
        help='Initial request rate (QPS)',
    )
    parser.add_argument(
        '--multiplier',
        type=float,
        default=1.25,
        help='Geometric multiplier for each step',
    )
    parser.add_argument(
        '--max-steps',
        type=int,
        default=12,
        help='Maximum number of sweep steps',
    )
    parser.add_argument(
        '--duration',
        type=int,
        default=180,
        help='Measurement duration per step (seconds)',
    )
    parser.add_argument(
        '--warmup',
        type=int,
        default=30,
        help='Warmup duration (seconds, excluded from metrics)',
    )
    parser.add_argument(
        '--max-concurrency',
        type=int,
        default=512,
        help='Maximum concurrent requests (client-side limit)',
    )
    
    # Stop condition configuration
    parser.add_argument(
        '--sla-p99-ms',
        type=float,
        default=2000.0,
        help='SLA for P99 latency in milliseconds (stop condition S1)',
    )
    parser.add_argument(
        '--achieved-ratio-min',
        type=float,
        default=0.90,
        help='Minimum achieved/requested QPS ratio (stop condition S2)',
    )
    parser.add_argument(
        '--p95-jump-frac',
        type=float,
        default=0.30,
        help='P95 latency jump threshold as fraction (stop condition S2)',
    )
    
    # Output configuration
    parser.add_argument(
        '--log-dir',
        type=Path,
        default=Path('/persistent/logs/vllm'),
        help='Directory for log files and results',
    )
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Enable verbose logging',
    )
    
    args = parser.parse_args()
    
    # Create discovery instance
    discovery = CapacityDiscovery(
        model=args.model,
        tokenizer=args.tokenizer,
        base_url=args.base_url,
        endpoint=args.endpoint,
        input_tokens=args.input_tokens,
        output_tokens=args.output_tokens,
        lambda_start=args.lambda_start,
        multiplier=args.multiplier,
        max_steps=args.max_steps,
        duration_s=args.duration,
        warmup_s=args.warmup,
        max_concurrency=args.max_concurrency,
        sla_p99_ms=args.sla_p99_ms,
        achieved_ratio_min=args.achieved_ratio_min,
        p95_jump_frac=args.p95_jump_frac,
        log_dir=args.log_dir,
        verbose=args.verbose,
    )
    
    try:
        # Run discovery
        result = discovery.discover()
        
        # Save results
        discovery.save_results(result)
        
        return 0
        
    except KeyboardInterrupt:
        logging.error("Discovery interrupted by user")
        return 130
    except Exception as e:
        logging.error(f"Discovery failed: {e}", exc_info=args.verbose)
        return 1


if __name__ == '__main__':
    sys.exit(main())

