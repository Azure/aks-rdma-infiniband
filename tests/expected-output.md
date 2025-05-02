# Expected Outputs of Tests

## 1. sriov-nic-policy-gpu

### 1.1. mpijob

To start a `mpijob` in a `sriov-nic-policy-gpu` scenario, run the following command:

```bash
./tests/scenarios/test.sh sriov-nic-policy-gpu mpijob
```

Expected output:

```bash
...
#                                                              out-of-place                       in-place
#       size         count      type   redop    root     time   algbw   busbw #wrong     time   algbw   busbw #wrong
#        (B)    (elements)                               (us)  (GB/s)  (GB/s)            (us)  (GB/s)  (GB/s)
           8             2     float     sum      -1    99.09    0.00    0.00    N/A    36.48    0.00    0.00    N/A
          32             8     float     sum      -1    42.16    0.00    0.00    N/A    37.16    0.00    0.00    N/A
         128            32     float     sum      -1    37.41    0.00    0.01    N/A    36.15    0.00    0.01    N/A
         512           128     float     sum      -1    38.83    0.01    0.02    N/A    37.04    0.01    0.03    N/A
        2048           512     float     sum      -1    42.16    0.05    0.09    N/A    40.09    0.05    0.10    N/A
        8192          2048     float     sum      -1    50.79    0.16    0.30    N/A    47.13    0.17    0.33    N/A
       32768          8192     float     sum      -1    51.15    0.64    1.20    N/A    49.71    0.66    1.24    N/A
      131072         32768     float     sum      -1    55.33    2.37    4.44    N/A    54.01    2.43    4.55    N/A
      524288        131072     float     sum      -1    325.2    1.61    3.02    N/A    78.95    6.64   12.45    N/A
     2097152        524288     float     sum      -1    124.0   16.91   31.70    N/A    125.9   16.65   31.22    N/A
     8388608       2097152     float     sum      -1    199.0   42.16   79.05    N/A    199.7   42.00   78.76    N/A
    33554432       8388608     float     sum      -1    618.8   54.22  101.67    N/A    629.2   53.33   99.99    N/A
   134217728      33554432     float     sum      -1   1737.8   77.23  144.81    N/A   2204.3   60.89  114.17    N/A
   536870912     134217728     float     sum      -1   5760.3   93.20  174.75    N/A   5674.2   94.62  177.41    N/A
  2147483648     536870912     float     sum      -1    21845   98.30  184.32    N/A    21781   98.59  184.86    N/A
  8589934592    2147483648     float     sum      -1    86026   99.85  187.22    N/A    86106   99.76  187.05    N/A
# Out of bounds values : 0 OK
# Avg bus bandwidth    : 56.3994
...
```

If the last value in the `busbw` column is less than 180, it indicates that there is a problem with the setup.

### 1.2. rdma-test

To start a `rdma-test` in a `sriov-nic-policy-gpu` scenario, run the following command:

```bash
./tests/scenarios/test.sh sriov-nic-policy-gpu rdma-test
```

**Expected output**

In this test, we run `ibv_rc_pingpong`, `ib_read_lat`, `ib_read_bw` and `ib_write_bw` for each of the IB devices named `mlx5_0`, `mlx5_1`, etc. The `leader` starts the test in server mode and the `worker` starts the test in client mode. The leader output is not so helpful other than the fact that it shows that the server has started. The worker output is more informative and shows the results of the tests.

- **1. `ibv_rc_pingpong`**:

Here is a typical output of a `worker`:

```bash
...
Starting RDMA client 'ibv_rc_pingpong' for mlx5_0 (Port 18515)...

8192000 bytes in 0.01 seconds = 7643.57 Mbit/sec
1000 iters in 0.01 seconds = 8.57 usec/iter
...
```

- Speed: You should see the speed greater than 7000 Mbit/sec.
- Time: For 1000 iterations the average time should be less than 9.5 usec/iter.

- **2. `ib_read_lat`**:

Here is a typical output of a `worker`:

```bash
...
Starting RDMA client 'ib_read_lat' for mlx5_0 (Port 18515)...

...
---------------------------------------------------------------------------------------
 #bytes #iterations    t_min[usec]    t_max[usec]  t_typical[usec]    t_avg[usec]    t_stdev[usec]   99% percentile[usec]   99.9% percentile[usec]
 2       1000          5.35           11.78        5.49               5.50           0.18            5.74                   11.78
---------------------------------------------------------------------------------------
...
```

You should see the average time (t_avg) less than 6 usec for 1000 iterations.

- **3. `ib_read_bw`**:

```bash
...
Starting RDMA client 'ib_read_bw' for mlx5_0 (Port 18515)...
...
---------------------------------------------------------------------------------------
 #bytes     #iterations    BW peak[Gb/sec]    BW average[Gb/sec]   MsgRate[Mpps]
 2          5000           0.045444            0.045291            2.830684
 4          5000           0.090887            0.090863            2.839461
 8          5000             0.18               0.18               2.836814
 16         5000             0.36               0.36               2.838234
 32         5000             0.73               0.73               2.838864
 64         5000             1.45               1.45               2.835428
 128        5000             2.91               2.88               2.815767
 256        5000             5.77               5.74               2.801258
 512        5000             11.36              11.23              2.740483
 1024       5000             22.48              22.47              2.743466
 2048       5000             44.13              44.12              2.692665
 4096       5000             76.39              76.33              2.329335
 8192       5000             125.80             116.65             1.779918
 16384      5000             169.95             154.71             1.180321
 32768      5000             192.97             184.51             0.703860
 65536      5000             189.63             185.13             0.353108
 131072     5000             194.66             193.47             0.184512
 262144     5000             190.64             190.46             0.090819
 524288     5000             190.98             190.97             0.045532
 1048576    5000             193.95             193.95             0.023120
 2097152    5000             197.34             197.34             0.011762
 4194304    5000             197.45             197.45             0.005885
 8388608    5000             197.48             197.48             0.002943
---------------------------------------------------------------------------------------
...
```

You should see the average bandwidth greater than 190 Gb/sec.

- **4. `ib_write_bw`**:

```bash
...
Starting RDMA client 'ib_write_bw' for mlx5_0 (Port 18515)...
...
---------------------------------------------------------------------------------------
 #bytes     #iterations    BW peak[Gb/sec]    BW average[Gb/sec]   MsgRate[Mpps]
 2          5000           0.045656            0.045526            2.845402
 4          5000           0.091312            0.091284            2.852624
 8          5000             0.18               0.18               2.849480
 16         5000             0.37               0.36               2.850262
 32         5000             0.73               0.73               2.852608
 64         5000             1.46               1.46               2.851239
 128        5000             2.92               2.90               2.828486
 256        5000             5.81               5.80               2.830588
 512        5000             11.58              11.56              2.821211
 1024       5000             23.08              23.07              2.816402
 2048       5000             45.58              45.54              2.779293
 4096       5000             89.63              89.61              2.734552
 8192       5000             178.27             147.61             2.252403
 16384      5000             193.91             168.13             1.282763
 32768      5000             195.50             186.48             0.711349
 65536      5000             195.89             190.24             0.362863
 131072     5000             195.56             192.64             0.183712
 262144     5000             194.06             193.66             0.092344
 524288     5000             195.68             195.52             0.046616
 1048576    5000             196.29             196.29             0.023399
 2097152    5000             196.38             196.38             0.011705
 4194304    5000             196.64             196.64             0.005860
 8388608    5000             196.56             196.55             0.002929
---------------------------------------------------------------------------------------
...
```

You should see the average bandwidth greater than 190 Gb/sec.

### 1.3. nccl-test-gpudirect-rdma

To start a `nccl-test-gpudirect-rdma` in a `sriov-nic-policy-gpu` scenario, run the following command:

```bash
./tests/scenarios/test.sh sriov-nic-policy-gpu nccl-test-gpudirect-rdma
```

**Expected output**

Here is a typical output of a `leader`:

```bash
...
[Rank 1] AllReduce time for 10 iterations: 0.005877 seconds
[Rank 6] AllReduce time for 10 iterations: 0.005890 seconds
[Rank 2] AllReduce time for 10 iterations: 0.005877 seconds
[Rank 4] AllReduce time for 10 iterations: 0.005892 seconds
[Rank 7] AllReduce time for 10 iterations: 0.005901 seconds
[Rank 0] AllReduce time for 10 iterations: 0.005900 seconds
[Rank 5] AllReduce time for 10 iterations: 0.005871 seconds
[Rank 3] AllReduce time for 10 iterations: 0.005896 seconds
...
```

Here is a typical output of a `worker`:

```bash
...
[Rank 12] AllReduce time for 10 iterations: 0.005878 seconds
[Rank 14] AllReduce time for 10 iterations: 0.005876 seconds
[Rank 13] AllReduce time for 10 iterations: 0.005882 seconds
[Rank 8] AllReduce time for 10 iterations: 0.005870 seconds
[Rank 11] AllReduce time for 10 iterations: 0.005879 seconds
[Rank 10] AllReduce time for 10 iterations: 0.005872 seconds
[Rank 15] AllReduce time for 10 iterations: 0.005881 seconds
[Rank 9] AllReduce time for 10 iterations: 0.005865 seconds
...
```

The output shows the time taken for the `AllReduce` operation for 10 iterations. The time should be less than 0.006 seconds.

### 1.4. nccl-test-vllm-rdma

To start a `nccl-test-vllm-rdma` in a `sriov-nic-policy-gpu` scenario, run the following command:

```bash
./tests/scenarios/test.sh sriov-nic-policy-gpu nccl-test-vllm-rdma
```

**Expected output**

The output of the `leader` and `worker` is similar. Here is a typical output of a `leader`:

```bash
+ bash /root/tests/test-runner.sh nccl-test-vllm-rdma
...
PyTorch NCCL is successful!
PyTorch GLOO is successful!
PyTorch GLOO is successful!
INFO 04-23 16:35:15 [pynccl.py:69] vLLM is using nccl==2.21.5
INFO 04-23 16:35:15 [utils.py:931] Found nccl from library libnccl.so.2
vLLM NCCL is successful!
vLLM NCCL is successful!
vLLM NCCL is successful!
vLLM NCCL with cuda graph is successful!vLLM NCCL with cuda graph is successful!vLLM NCCL with cuda graph is successful!vLLM NCCL with cuda graph is successful!vLLM NCCL with cuda graph is successful!vLLM NCCL with cuda graph is successful!vLLM NCCL with cuda graph is successful!vLLM NCCL with cuda graph is successful!
```

Look for the lines like the following to ensure this test is successful:

- `PyTorch GLOO is successful!`
- `vLLM NCCL is successful!`
- `vLLM NCCL with cuda graph is successful!`

### 1.5. sockperf

To start a `sockperf` test in a `sriov-nic-policy-gpu` scenario, run the following command:

```bash
./tests/scenarios/test.sh sriov-nic-policy-gpu sockperf
```

> [!NOTE]
> Sometimes `sockperf` may fail with intermittent errors like: `sockperf: '-i/-p': invalid host:port value: Name or service not known`. You can rerun the test until it succeeds.

**Expected output**

The output of the `leader` is not so helpful other than the fact that it shows that the sockperf server has started. Here is a typical output:

```bash
✅ Job 'role=leader' in namespace 'default' succeeded. Printing logs...

+ bash /root/tests/test-runner.sh sockperf
...
Starting sockperf test...
...
Starting sockperf test server on eth0 interface...

sockperf: Running as daemon
sockperf: == version #3.10-no.git ==
sockperf: [SERVER] listen on:
[ 0] IP = 10.244.2.109    PORT = 11112 # TCP
...
```

The output of the `worker` is more informative and shows the results of the tests. Here is a typical output:

```bash
✅ Job 'role=worker' in namespace 'default' succeeded. Printing logs...

+ bash /root/tests/test-runner.sh sockperf
...
Starting sockperf test...

Endpoint leader:11112 is reachable.

Running ping-pong test on eth0 interface...

sockperf: == version #3.10-no.git ==
sockperf[CLIENT] send on:sockperf: using recvfrom() to block on socket(s)

[ 0] IP = 10.244.2.109    PORT = 11112 # TCP
...
sockperf: [Total Run] RunTime=10.000 sec; Warm up time=400 msec; SentMessages=59986; ReceivedMessages=59985
sockperf: ========= Printing statistics for Server No: 0
sockperf: [Valid Duration] RunTime=9.550 sec; SentMessages=57400; ReceivedMessages=57400
sockperf: ====> avg-latency=83.147 (std-dev=8.246, mean-ad=4.603, median-ad=4.552, siqr=3.649, cv=0.099, std-error=0.034, 99.0% ci=[83.058, 83.236])
sockperf: # dropped messages = 0; # duplicated messages = 0; # out-of-order messages = 0
sockperf: Summary: Latency is 83.147 usec
sockperf: Total 57400 observations; each percentile contains 574.00 observations
sockperf: ---> <MAX> observation = 1245.549
sockperf: ---> percentile 99.999 =  625.001
sockperf: ---> percentile 99.990 =  174.150
sockperf: ---> percentile 99.900 =  108.442
sockperf: ---> percentile 99.000 =   98.909
sockperf: ---> percentile 90.000 =   90.509
sockperf: ---> percentile 75.000 =   86.717
sockperf: ---> percentile 50.000 =   81.171
sockperf: ---> percentile 25.000 =   79.418
sockperf: ---> <MIN> observation =   67.035
Endpoint leader:11112 is reachable.

Running throughput test on eth0 interface...


sockperf: == version #3.10-no.git ==
sockperf[CLIENT] send on:
[ 0] IP = 10.244.2.109    PORT = 11112 # TCP
...
sockperf: Total of 127155 messages sent in 1.000 sec

sockperf: Summary: Message Rate is 127096 [msg/sec]
sockperf: Summary: BandWidth is 178.418 MBps (1427.348 Mbps)
```

The output shows that two type of tests were run, `ping-pong` and `throughput`. The `ping-pong` test shows the average latency, while the `throughput` test shows the message rate and bandwidth.

Expected values:

- `ping-pong` average latency should be less than 100 microseconds.
- `throughput`
  - Message Rate: Should be greater than 110,000 msg/sec.
  - Bandwidth: Should be greater than 1200 Mbps.

## 2. rdma-shared-device-plugin-gpu

### 2.1. mpijob

To start a `mpijob` in a `rdma-shared-device-plugin-gpu` scenario, run the following command:

```bash
./tests/scenarios/test.sh rdma-shared-device-plugin-gpu mpijob
```

The expected output will be similar to the `mpijob` output in the `sriov-nic-policy-gpu` scenario, [here](#11-mpijob).

### 2.2. rdma-test

To start a `rdma-test` in a `rdma-shared-device-plugin-gpu` scenario, run the following command:

```bash
./tests/scenarios/test.sh rdma-shared-device-plugin-gpu rdma-test
```

The expected output will be similar to the `rdma-test` output in the `sriov-nic-policy-gpu` scenario, [here](#12-rdma-test).

### 2.3. nccl-test-gpudirect-rdma

To start a `nccl-test-gpudirect-rdma` in a `rdma-shared-device-plugin-gpu` scenario, run the following command:

```bash
./tests/scenarios/test.sh rdma-shared-device-plugin-gpu nccl-test-gpudirect-rdma
```

The expected output will be similar to the `nccl-test-gpudirect-rdma` output in the `sriov-nic-policy-gpu` scenario, [here](#13-nccl-test-gpudirect-rdma).

### 2.4. nccl-test-vllm-rdma

To start a `nccl-test-vllm-rdma` in a `rdma-shared-device-plugin-gpu` scenario, run the following command:

```bash
./tests/scenarios/test.sh rdma-shared-device-plugin-gpu nccl-test-vllm-rdma
```

The expected output will be similar to the `nccl-test-vllm-rdma` output in the `sriov-nic-policy-gpu` scenario, [here](#14-nccl-test-vllm-rdma).

### 2.5. sockperf

To start a `sockperf` test in a `rdma-shared-device-plugin-gpu` scenario, run the following command:

```bash
./tests/scenarios/test.sh rdma-shared-device-plugin-gpu sockperf
```

The expected output will be similar to the `sockperf` output in the `sriov-nic-policy-gpu` scenario, [here](#15-sockperf).

## 3. ipoib-nic-policy-gpu

### 3.1. mpijob

To start a `mpijob` in a `ipoib-nic-policy-gpu` scenario, run the following command:

```bash
./tests/scenarios/test.sh ipoib-nic-policy-gpu mpijob
```

Expected output:

```bash
...
#                                                              out-of-place                       in-place
#       size         count      type   redop    root     time   algbw   busbw #wrong     time   algbw   busbw #wrong
#        (B)    (elements)                               (us)  (GB/s)  (GB/s)            (us)  (GB/s)  (GB/s)
           8             2     float     sum      -1    82.21    0.00    0.00    N/A    79.73    0.00    0.00    N/A
          32             8     float     sum      -1    83.46    0.00    0.00    N/A    78.44    0.00    0.00    N/A
         128            32     float     sum      -1    77.11    0.00    0.00    N/A    79.77    0.00    0.00    N/A
         512           128     float     sum      -1    200.6    0.00    0.00    N/A    80.81    0.01    0.01    N/A
        2048           512     float     sum      -1    92.53    0.02    0.04    N/A    95.44    0.02    0.04    N/A
        8192          2048     float     sum      -1    687.9    0.01    0.02    N/A    123.2    0.07    0.12    N/A
       32768          8192     float     sum      -1    182.7    0.18    0.34    N/A    195.9    0.17    0.31    N/A
      131072         32768     float     sum      -1    503.8    0.26    0.49    N/A    480.1    0.27    0.51    N/A
      524288        131072     float     sum      -1    943.7    0.56    1.04    N/A   1011.5    0.52    0.97    N/A
     2097152        524288     float     sum      -1   2553.1    0.82    1.54    N/A   2068.7    1.01    1.90    N/A
     8388608       2097152     float     sum      -1   5563.0    1.51    2.83    N/A   5476.7    1.53    2.87    N/A
    33554432       8388608     float     sum      -1    20124    1.67    3.13    N/A    20197    1.66    3.12    N/A
   134217728      33554432     float     sum      -1    79408    1.69    3.17    N/A    79573    1.69    3.16    N/A
   536870912     134217728     float     sum      -1   320846    1.67    3.14    N/A   319667    1.68    3.15    N/A
  2147483648     536870912     float     sum      -1  1270070    1.69    3.17    N/A  1275973    1.68    3.16    N/A
  8589934592    2147483648     float     sum      -1  5111454    1.68    3.15    N/A  5220040    1.65    3.09    N/A
# Out of bounds values : 0 OK
# Avg bus bandwidth    : 1.38997
```

If the last value in the `busbw` column is less than 3, it indicates that there is a problem with the setup.

### 3.2. nccl-test-gpudirect-rdma

To start a `nccl-test-gpudirect-rdma` in a `ipoib-nic-policy-gpu` scenario, run the following command:

```bash
./tests/scenarios/test.sh ipoib-nic-policy-gpu nccl-test-gpudirect-rdma
```

**Expected output**

Here is a typical output of a `leader`:

```bash
[Rank 2] AllReduce time for 10 iterations: 0.050383 seconds
[Rank 3] AllReduce time for 10 iterations: 0.050512 seconds
[Rank 1] AllReduce time for 10 iterations: 0.050388 seconds
[Rank 4] AllReduce time for 10 iterations: 0.050481 seconds
[Rank 5] AllReduce time for 10 iterations: 0.050406 seconds
[Rank 6] AllReduce time for 10 iterations: 0.050393 seconds
[Rank 7] AllReduce time for 10 iterations: 0.050294 seconds
[Rank 0] AllReduce time for 10 iterations: 0.050264 seconds
```

Here is a typical output of a `worker`:

```bash
...
[Rank 9] AllReduce time for 10 iterations: 0.050301 seconds
[Rank 10] AllReduce time for 10 iterations: 0.050332 seconds
[Rank 11] AllReduce time for 10 iterations: 0.050344 seconds
[Rank 12] AllReduce time for 10 iterations: 0.050325 seconds
[Rank 13] AllReduce time for 10 iterations: 0.050288 seconds
[Rank 14] AllReduce time for 10 iterations: 0.050337 seconds
[Rank 8] AllReduce time for 10 iterations: 0.050277 seconds
[Rank 15] AllReduce time for 10 iterations: 0.050232 seconds
...
```

The output shows the time taken for the `AllReduce` operation for 10 iterations. The time should be less than 0.06 seconds. This is 10x slower than the `sriov-nic-policy-gpu` and `rdma-shared-device-plugin-gpu` scenario.

### 3.3. nccl-test-vllm-rdma

To start a `nccl-test-vllm-rdma` in a `ipoib-nic-policy-gpu` scenario, run the following command:

```bash
./tests/scenarios/test.sh ipoib-nic-policy-gpu nccl-test-vllm-rdma
```

The expected output will be similar to the `nccl-test-vllm-rdma` output in the `sriov-nic-policy-gpu` scenario, [here](#14-nccl-test-vllm-rdma).

### 3.4. sockperf

To start a `sockperf` test in a `ipoib-nic-policy-gpu` scenario, run the following command:

```bash
./tests/scenarios/test.sh ipoib-nic-policy-gpu sockperf
```

**Expected output**

The output of the `leader` is not so helpful other than the fact that it shows that the sockperf server has started. The noticeble difference is that the `sockperf` server is started on `net1` interface in addition to the `eth0` interface. Here is a typical output:

```bash
✅ Job 'role=leader' in namespace 'default' succeeded. Printing logs...

+ bash /root/tests/test-runner.sh sockperf
...
Starting sockperf test...
...
Starting sockperf test server on IPOIB interface...
...
Starting sockperf test server on eth0 interface...

sockperf: Running as daemon
sockperf: == version #3.10-no.git ==
sockperf: [SERVER] listen on:
[ 0] IP = 192.168.0.1     PORT = 11111 # TCP
...
sockperf: Running as daemon
sockperf: == version #3.10-no.git ==
sockperf: [SERVER] listen on:
[ 0] IP = 10.244.2.84     PORT = 11112 # TCP
...
```

Here we will not ponder upon the results from the `eth0` interface, you can expect the results to be similar to the `sockperf` test in the `sriov-nic-policy-gpu` scenario, [here](#15-sockperf). Here is a typical output of the `worker`:

```bash
✅ Job 'role=worker' in namespace 'default' succeeded. Printing logs...

+ bash /root/tests/test-runner.sh sockperf
...
Starting sockperf test...
...
Running ping-pong test on IPOIB interface...

sockperf: == version #3.10-no.git ==
sockperf[CLIENT] send on:sockperf: using recvfrom() to block on socket(s)

[ 0] IP = 192.168.0.1     PORT = 11111 # TCP
...
sockperf: [Total Run] RunTime=10.000 sec; Warm up time=400 msec; SentMessages=112790; ReceivedMessages=112789
sockperf: ========= Printing statistics for Server No: 0
sockperf: [Valid Duration] RunTime=9.550 sec; SentMessages=107254; ReceivedMessages=107254
sockperf: ====> avg-latency=44.475 (std-dev=764.905, mean-ad=11.200, median-ad=6.542, siqr=4.420, cv=17.199, std-error=2.336, 99.0% ci=[38.459, 50.491])
sockperf: # dropped messages = 0; # duplicated messages = 0; # out-of-order messages = 0
sockperf: Summary: Latency is 44.475 usec
sockperf: Total 107254 observations; each percentile contains 1072.54 observations
sockperf: ---> <MAX> observation = 125996.233
sockperf: ---> percentile 99.999 = 125790.528
sockperf: ---> percentile 99.990 =  120.725
sockperf: ---> percentile 99.900 =   57.692
sockperf: ---> percentile 99.000 =   53.354
sockperf: ---> percentile 90.000 =   49.943
sockperf: ---> percentile 75.000 =   43.190
sockperf: ---> percentile 50.000 =   38.727
sockperf: ---> percentile 25.000 =   34.349
sockperf: ---> <MIN> observation =   30.116

Running throughput test on IPOIB interface...


sockperf: == version #3.10-no.git ==
sockperf[CLIENT] send on:
[ 0] IP = 192.168.0.1     PORT = 11111 # TCP
...
sockperf: Total of 593671 messages sent in 1.000 sec

sockperf: Summary: Message Rate is 593397 [msg/sec]
sockperf: Summary: BandWidth is 833.016 MBps (6664.126 Mbps)
```

The output shows that two type of tests were run, `ping-pong` and `throughput`. The `ping-pong` test shows the average latency, while the `throughput` test shows the message rate and bandwidth.

Expected values:

- `ping-pong` average latency should be less than 50 microseconds.
- `throughput`
  - Message Rate: Should be greater than 500,000 msg/sec.
  - Bandwidth: Should be greater than 6000 Mbps.

## 4. sriov-nic-policy

### 4.1. rdma-test

To start a `rdma-test` in a `sriov-nic-policy` scenario, run the following command:

```bash
./tests/scenarios/test.sh sriov-nic-policy rdma-test
```

The expected output will be similar to the `rdma-test` output in the `sriov-nic-policy-gpu` scenario, [here](#12-rdma-test).

### 4.2. sockperf

To start a `sockperf` test in a `sriov-nic-policy` scenario, run the following command:

```bash
./tests/scenarios/test.sh sriov-nic-policy sockperf
```

The expected output will be similar to the `sockperf` output in the `sriov-nic-policy-gpu` scenario, [here](#15-sockperf).

## 5. rdma-shared-device-plugin

### 5.1. rdma-test

To start a `rdma-test` in a `rdma-shared-device-plugin` scenario, run the following command:

```bash
./tests/scenarios/test.sh rdma-shared-device-plugin rdma-test
```

The expected output will be similar to the `rdma-test` output in the `sriov-nic-policy-gpu` scenario, [here](#12-rdma-test).

### 5.2. sockperf

To start a `sockperf` test in a `rdma-shared-device-plugin` scenario, run the following command:

```bash
./tests/scenarios/test.sh rdma-shared-device-plugin sockperf
```

The expected output will be similar to the `sockperf` output in the `sriov-nic-policy-gpu` scenario, [here](#15-sockperf).

## 6. ipoib-nic-policy

### 6.1. sockperf

To start a `sockperf` test in a `ipoib-nic-policy` scenario, run the following command:

```bash
./tests/scenarios/test.sh ipoib-nic-policy sockperf
```

The expected output will be similar to the `sockperf` output in the `ipoib-nic-policy-gpu` scenario, [here](#34-sockperf).
