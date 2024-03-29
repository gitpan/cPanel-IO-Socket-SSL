#!perl

use strict;
use warnings;
use Net::SSLeay;
use Socket;
use cPanel::IO::Socket::SSL;

if ( grep { $^O =~m{$_} } qw( MacOS VOS vmesa riscos amigaos ) ) {
    print "1..0 # Skipped: fork not implemented on this platform\n";
    exit
}

if ( $^O =~m{mswin32}i ) {
    print "1..0 # Skipped: signals not relevant on this platform\n";
    exit
}

print "1..9\n";

my $server = cPanel::IO::Socket::SSL->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 0,
    Listen => 2,
    SSL_server => 1,
    SSL_ca_file => "certs/test-ca.pem",
    SSL_cert_file => "certs/server-wildcard.pem",
    SSL_key_file => "certs/server-wildcard.pem",
);
warn "\$!=$!, \$\@=$@, S\$SSL_ERROR=$SSL_ERROR" if ! $server;
print "not ok\n", exit if !$server;
ok("Server Initialization");
my $saddr = $server->sockhost.':'.$server->sockport;

defined( my $pid = fork() ) || die $!;
if ( $pid == 0 ) {

    $SIG{HUP} = sub { ok("got hup") };

    close($server);
    my $client = cPanel::IO::Socket::SSL->new(
	PeerAddr => $saddr,
	SSL_verify_mode => 0
    ) || print "not ";
    ok( "client ssl connect" );

    my $line = <$client>;
    print "not " if $line ne "foobar\n";
    ok("got line");

    exit;
}

my $csock = $server->accept;
ok("accept");
$SIG{PIPE} = 'IGNORE';

syswrite($csock,"foo") or print "not ";
ok("wrote foo");
sleep(1);

kill HUP => $pid or print "not ";
ok("send hup");
sleep(1);

syswrite($csock,"bar\n") or print "not ";
ok("wrote bar\\n");

wait;
ok("wait: $?");



sub ok { print "ok #$_[0]\n"; }
