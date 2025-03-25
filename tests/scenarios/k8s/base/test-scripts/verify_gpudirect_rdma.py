#!/usr/bin/env python3

import os
import time
import torch
import torch.distributed as dist

def main():
    # Set NCCL debug environment variables
    os.environ["NCCL_DEBUG"] = "INFO"
    os.environ["NCCL_DEBUG_SUBSYS"] = "INIT,NET"
    os.environ["NCCL_IB_DISABLE"] = "0"
    os.environ["NCCL_P2P_LEVEL"] = "NVL"

    # Initialize the distributed process group with NCCL backend
    dist.init_process_group(backend="nccl")
    rank = dist.get_rank()
    world_size = dist.get_world_size()
    local_rank = rank % torch.cuda.device_count()
    torch.cuda.set_device(local_rank)
    print(f"[Rank {rank}] Using device {local_rank}")

    # Create a tensor on CUDA and fill it with ones.
    tensor = torch.ones(1024 * 1024, dtype=torch.float32, device="cuda")

    # Warmup: perform a few all_reduce calls.
    for _ in range(5):
        dist.all_reduce(tensor, op=dist.ReduceOp.SUM)
        torch.cuda.synchronize()

    # Benchmark: perform 10 all_reduce iterations (results here will be cumulative)
    start = time.time()
    for _ in range(10):
        dist.all_reduce(tensor, op=dist.ReduceOp.SUM)
    torch.cuda.synchronize()
    end = time.time()
    print(f"[Rank {rank}] AllReduce time for 10 iterations: {end - start:.6f} seconds")

    # Reset tensor to ones for a correctness check.
    tensor.fill_(1.0)
    dist.all_reduce(tensor, op=dist.ReduceOp.SUM)
    torch.cuda.synchronize()

    # Now each element should equal the number of ranks (i.e. world_size).
    expected = world_size
    avg = tensor.mean().item()
    print(f"[Rank {rank}] After reset, Tensor dtype: {tensor.dtype}, mean: {avg}, sample: {tensor[:5]}")
    assert abs(avg - expected) < 1e-3, f"[Rank {rank}] Expected {expected}, got {avg}"

    dist.destroy_process_group()

if __name__ == "__main__":
    main()
