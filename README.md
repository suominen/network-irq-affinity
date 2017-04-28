Network IRQ Affinity
====================

This script sets the CPU affinity for network interfaces across all
the CPUs in an efficient manner. By default the Linux kernel assigns
all queues and interfaces in CPU ID 0. This can become a performance
bottleneck.

Known Issues
------------

Currently only the queues created by the following drivers are
assigned:

* e1000e
* igb
* xen_netfront

I think I would want to keep each interface on its own CPU, but also
on the same CPU as its possible queues. This probably should become
a second pass through the IRQs, while paying attention to the affinity
assigned to any queues in the first pass.
