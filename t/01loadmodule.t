use strict;
use warnings;
no warnings 'once';
use Test::More;

plan tests => 3;

ok( eval { require cPanel::IO::Socket::SSL },"loaded");

diag( sprintf( "openssl version=0x%0x", Net::SSLeay::OPENSSL_VERSION_NUMBER()));
diag( sprintf( "Net::SSLeay::VERSION=%s", $Net::SSLeay::VERSION));

cPanel::IO::Socket::SSL->import(':debug1');
is( $cPanel::IO::Socket::SSL::DEBUG,1, "cPanel::IO::Socket::SSL::DEBUG 1");
is( $Net::SSLeay::trace,1, "Net::SSLeay::trace 1");

