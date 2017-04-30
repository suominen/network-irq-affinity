Network IRQ Affinity
====================

This script sets the CPU affinity for network interfaces and interface
queues across all the CPUs in an efficient manner.

By default many drivers set their SMP affinity mask to either zero or
all ones ("ff" -- length depends on the number of CPUs on the system).
The former results in all queues and interfaces running on CPU ID 0,
which can become a performance bottleneck due to insufficient computing
power. The latter results in all queues and interfaces being scheduled
on multiple CPUs, which can become a performance bottleneck due to
increased CPU memory cache misses.

Some drivers create multiple queues each with its own IRQ, which then
can each be assigned to its own CPU. Drivers appear to create as many
queues as there are CPUs, unless the NIC hardware capabilities limit
the total to a lower number.

Some drivers create separate transmit (TX) and receive (RX) queues.
For optimal cache hits, the TX and RX sides of a given queue must be
scheduled on the same CPU.

Even without multiple queues, a performance boost can be attained on
multihomed hosts and when using bonded interfaces by assigning each
NIC to a separate CPU.


Known Issues
------------

Only queues matching the naming schemes implemented in the following
drivers are assigned:

* e1000e
* igb
* sfc
* xen_netfront

Please send pull requests for additional naming schemes.


See Also
--------

* [Scaling in the Linux Networking Stack][1]
* [SMP IRQ Affinity][2]
* [Irqbalance][3]

[1]: https://www.kernel.org/doc/Documentation/networking/scaling.txt
[2]: https://www.kernel.org/doc/Documentation/IRQ-affinity.txt
[3]: https://github.com/Irqbalance/irqbalance
