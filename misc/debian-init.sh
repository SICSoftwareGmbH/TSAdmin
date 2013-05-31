#! /bin/sh

### BEGIN INIT INFO
# Provides:		tsadmin
# Required-Start:	$remote_fs $syslog
# Required-Stop:	$remote_fs $syslog
# Default-Start:	2 3 4 5
# Default-Stop:		
# Short-Description: Apache Traffic Server frontend
### END INIT INFO

set -e

PATH=/usr/local/sbin:/usr/local/bin:$PATH

DAEMON=`which ts-admin`
PIDFILE=/var/run/ts-admin.pid
CONFIG=/etc/ts-admin/config.yml

test -x "$DAEMON" || exit 0

if test -f /etc/default/ts-admin; then
  . /etc/default/ts-admin
fi

. /lib/lsb/init-functions

case "$1" in
  start)
	log_daemon_msg "Starting TSAdmin" "ts-admin" || true
	if start-stop-daemon --start --quiet --background --oknodo --make-pidfile --pidfile "$PIDFILE" --exec "$DAEMON" -- --config "$CONFIG"; then
	    log_end_msg 0 || true
	else
	    log_end_msg 1 || true
	fi
	;;
  stop)
	log_daemon_msg "Stopping TSAdmin" "ts-admin" || true
	if start-stop-daemon --stop --signal KILL --quiet --oknodo --pidfile "$PIDFILE"; then
	    log_end_msg 0 || true
	else
	    log_end_msg 1 || true
	fi
	;;

  reload|force-reload)
		$0 restart
	;;

  restart)
		$0 stop
		$0 start
	;;

  status)
	status_of_proc -p /var/run/sshd.pid /usr/sbin/sshd sshd && exit 0 || exit $?
	;;

  *)
	log_action_msg "Usage: /etc/init.d/ts-admin {start|stop|reload|force-reload|restart|status}" || true
	exit 1
esac

exit 0
