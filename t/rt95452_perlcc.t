use strict;
use warnings;

eval "use B::C;";
if ($@) {
  print "1..0 # SKIP B::C required for testing perlcc -O3\n";
  exit;
} elsif ($B::C::VERSION lt '1.48') {
  print "1..0 # SKIP testing too old B-C-$B::C::VERSION\n";
  exit;
} else {
  print "1..1\n";
}

my $f = "t/rt95452x.pl";
open my $fh, ">", $f; END { unlink $f }
print $fh 'use Net::SSLeay();use cPanel::IO::Socket::SSL();Net::SSLeay::OpenSSL_add_ssl_algorithms(); my $ssl_ctx = cPanel::IO::Socket::SSL::SSL_Context->new(SSL_server => 1); print q(ok);';
close $fh;

system($^X, qw(-Mblib -S perlcc -O3 -r), $f);

unlink "t/rt95452x", "t/rt95452x.exe";
# vim: ft=perl
