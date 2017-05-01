#
# Makefile for network-irq-affinity
#

PREFIX	= /usr
BINDIR	= ${PREFIX}/sbin
MANDIR	= ${PREFIX}/share/man

PROG	= network-irq-affinity

all:
# Nothing to be done for now.

install:
	install -m 0755 ${PROG}.sh ${DESTDIR}${BINDIR}/${PROG}
	install -m 0644 ${PROG}.8  ${DESTDIR}${MANDIR}/man8/${PROG}.8

clean:
# Nothing to be done for now.
