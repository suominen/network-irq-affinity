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

To Do
-----

1.  Add an option to set the affinity hint instead. This can be useful
    with [irqbalance(8)][3].
2.  Write a manual page.

See Also
--------

* [Scaling in the Linux Networking Stack][1]
* [SMP IRQ Affinity][2]
* [Irqbalance][3]

[1]: https://www.kernel.org/doc/Documentation/networking/scaling.txt
[2]: https://www.kernel.org/doc/Documentation/IRQ-affinity.txt
[3]: https://github.com/Irqbalance/irqbalance
