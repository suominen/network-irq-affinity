#!/bin/sh
#
# Copyright (c) 2017 Kimmo Suominen
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. The name of the author may not be used to endorse or promote
#    products derived from this software without specific prior
#    written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# ----------------------------------------------------------------------------

# Network drivers don't seem to create queues before the interface
# has been marked up. Therefore you'd want to call this script after
# the network has been fully configured.

# ----------------------------------------------------------------------------

PATH=/bin:/usr/bin
export PATH

PROG="${0##*/}"

# ----------------------------------------------------------------------------

die()
{
    echo "${PROG}: ${@}" 1>&2
    exit 1
}

fatal()
{
    echo "${PROG}: ${@}" 1>&2
}

verbose()
{
    if ${verbose}
    then
	echo "${PROG}: ${@}"
    fi
}

warn()
{
    if ! ${quiet}
    then
	echo "${PROG}: ${@}" 1>&2
    fi
}

usage()
{
    cat <<-EOF
	Usage:  ${PROG} [-hnqv]

	Options:
	-h	Show this usage message.
	-n	Do not change anything, just show what would be done.
	-q	Quiet; only output fatal errors.
	-v	Verbose output of changes made.
	EOF
}

# ----------------------------------------------------------------------------

# Having the nodes under each irq is pretty, but not all drivers populate
# them. E.g. sfc just puts a PCI bus address there.

network_irqs_from_each_irq()
{
    local dir irq queue
    for dir in /proc/irq/*/eth*
    do
	case "${dir}" in
	*'*'*)
	    ;;
	*)
	    queue="${dir##*/}"
	    dir="${dir%/*}"
	    irq="${dir##*/}"
	    echo "${queue}/${irq}"
	    ;;
	esac
    done
}

network_irqs()
{
    awk '
	$NF ~ /^eth/ {gsub(/:$/, "", $1); print $NF "/" $1;}
	' /proc/interrupts
}

recall_interface_cpu()
{
    echo "${1}" \
    | grep "^${2}-" \
    | sed -e 's,^.*-,,' \
    | sort -n \
    | sed -e 's,^.*/,,' -e 1q
}

recall_queue_cpu()
{
    echo "${1}" \
    | grep "^${2}/" \
    | sed -e 's,^.*/,,' -e 1q
}

remember_cpu()
{
    case "${1}" in
    '')
	;;
    *)
	echo "${1}"
	;;
    esac
    if ! echo "${1}" | grep -q "^${2}/"
    then
	echo "${2}/${3}"
    fi
}

set_affinity()
{
    local cpu file irq ok que

    irq="${1}"
    cpu="${2}"
    que="${3}"

    ok=false

    case "${cpu}" in
    '')
	cpu=$(echo "${cpulist}" | sed -e 1q)
	cpulist=$(echo "${cpulist}" | sed -e 1d ; echo "${cpu}")
	;;
    esac

    if ! echo "${cpulist}" | grep -q "${cpu}"
    then
	warn "Could not map ${que} to a CPU ID"
	cpu=0
    fi
    verbose "Assigning ${que} on IRQ ${irq} to CPU ${cpu}"
    if ${noop}
    then
	ok=true
    else
	file="/proc/irq/${irq}/smp_affinity_list"
	if [ -w "${file}" ]
	then
	    echo "${cpu}" > "${file}"
	    # This is for caching the CPU, not for actual success check.
	    ok=true
	else
	    fatal "Cannot write to '${file}'"
	fi
    fi
    if ${ok}
    then
	cpucache=$(remember_cpu "${cpucache}" "${que}" "${cpu}")
    fi
}

# ----------------------------------------------------------------------------

noop=false
quiet=false
verbose=false

while getopts hnqv opt
do
    case "${opt}" in
    h) usage; exit 0;;
    n) noop=true; quiet=false; verbose=true;;
    q) quiet=true; verbose=false;;
    v) verbose=true; quiet=false;;
    *) usage 1>&2; exit 1;;
    esac
done
shift $((${OPTIND} - 1))

# We assume all processors from 0 to N are online.
#ncpu=$(getconf _NPROCESSORS_ONLN)

# Obtain a list of online logical CPU IDs.
cpulist=$(lscpu -p=cpu | grep -v '^#' | cut -d, -f1)

cpucache=

for pass in 1 2
do
    for queirq in $(network_irqs)
    do
	que="${queirq%/*}"
	if echo "${cpucache}" | grep -q "^${que}/"
	then
	    continue
	fi

	cpu=
	dir=
	int="${que%%-*}"
	irq="${queirq##*/}"
	qno=

	case "${que}" in
	*-[rt]x-*)
	    # e100e
	    qno="${que##*-}"
	    case "${que}" in
	    *-rx-*)
		dir=tx
		;;
	    *)
		dir=rx
		;;
	    esac
	    cpu=$(recall_queue_cpu "${cpucache}" "${int}-${dir}-${qno}")
	    set_affinity "${irq}" "${cpu}" "${que}"
	    ;;
	*-TxRx-*)
	    # igb
	    set_affinity "${irq}" "${cpu}" "${que}"
	    ;;
	*-q*-[rt]x)
	    # xen_netfront
	    qno="${que#*-q}"
	    qno="${qno%-*}"
	    case "${que}" in
	    *-rx)
		dir=tx
		;;
	    *)
		dir=rx
		;;
	    esac
	    cpu=$(recall_queue_cpu "${cpucache}" "${int}-q${qno}-${dir}")
	    set_affinity "${irq}" "${cpu}" "${que}"
	    ;;
	*-[0-9]|*-[0-9][0-9]|*-[0-9][0-9][0-9])
	    # sfc
	    set_affinity "${irq}" "${cpu}" "${que}"
	    ;;
	*)
	    case "${pass}" in
	    2)
		cpu=$(recall_interface_cpu "${cpucache}" "${que}")
		set_affinity "${irq}" "${cpu}" "${que}"
		;;
	    esac
	    ;;
	esac
    done
done
