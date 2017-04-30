#
# Makefile for network-irq-affinity
#

PREFIX	= /usr
BINDIR	= ${PREFIX}/sbin
MANDIR	= ${PREFIX}/share/man

SCRIPTS	= network-irq-affinity
MAN	= ${SCRIPTS:C/(.*)/\1.8/}

CLEANFILES+=	${SCRIPTS}

.include <bsd.prog.mk>
