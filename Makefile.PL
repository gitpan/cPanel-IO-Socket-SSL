# vim: set sts=4 sw=4 ts=8 ai:

use 5.008; 
use ExtUtils::MakeMaker;


# Test to make sure that Net::SSLeay can be properly seeded!
unless (defined $ENV{EGD_PATH}) {
    foreach (qw(/var/run/egd-pool /dev/egd-pool /etc/egd-pool /etc/entropy)) {
	if (-S) { $ENV{EGD_PATH}=$_; last }
    }
}

$| = 1;

{
    # issue warning, if Net::SSLeay cannot find random generator
    # redefine __WARN__ only locally to allow detection of failures
    # in PREREQ_PM
    local $SIG{__WARN__} = sub {
	undef $SIG{__WARN__};
	my $warning  = shift;
	return unless $warning =~ /random/i;
	print "Net::SSLeay could not find a random number generator on\n";
	print "your system.  This will likely cause most of the tests\n";
	print "to fail.  Please see the README file for more information.\n";
	print "the message from Net::SSLeay was: $warning\n";

	# Taken from ExtUtils::MakeMaker 6.16 (Michael Schwern) so that 
	# the prompt() function can be emulated for older versions of ExtUtils::MakeMaker.
	my $isa_tty = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT));
	
	if ($isa_tty) {
	    print "Do you REALLY want to continue? [Default: no] ";
	    die "User cancelled install!\n" if (<STDIN> !~ /^y(?:es)?$/);
	} else {
	    die "Install cancelled.\n";
	}
    };

    if (! defined $ENV{SKIP_RNG_TEST}) {
	eval { require Net::SSLeay; $Net::SSLeay::trace=1; Net::SSLeay::randomize(); };
	die $@ if $@ =~ /cancelled/;
    } else {
	print "Random Number Generator test skipped.\n";
    }
}

{
    # don't support too old OpenSSL versions anymore, only causes trouble
    my $openssl = eval { 
	require Net::SSLeay; 
	Net::SSLeay::OPENSSL_VERSION_NUMBER()
    };
    die sprintf(
	"minimal required version for OpenSSL is 0.9.8, but your Net::SSLeay reports 0x%08x",
	$openssl) if $openssl && $openssl < 0x00908000;
}

# make sure that we have dualvar from the XS Version of Scalar::Util
if ( eval { require Scalar::Util } ) {
    eval { Scalar::Util::dualvar( 0,'' ) };
    die "You need the XS Version of Scalar::Util for dualvar() support" if ($@);
}

# check if we have something which handles IDN
if ( ! eval { require Net::IDN::Encode } and ! eval { require Net::LibIDN } and ! eval { require URI; URI->VERSION(1.50) }) {
    warn <<'EOM';

WARNING
No library for handling international domain names found.
It will work but croak if you try to verify an international name against
a certificate.
It's recommended to install either Net::IDN::Encode, Net::LibIDN or URI version>=1.50

EOM
}

# check if we have usable CA store
# on windows we might need to install Mozilla::CA
# settings for default path from openssl crypto/cryptlib.h
my %usable_ca;
{
    my $openssldir = eval { 
	require Net::SSLeay;
	Net::SSLeay::SSLeay_version(5) =~m{^OPENSSLDIR: "(.+)"$} && $1 || '';
    };
    my $dir = $ENV{SSL_CERT_DIR} 
	|| ( $^O =~m{vms}i ? "SSLCERTS:":"$openssldir/certs" );
    if ( opendir(my $dh,$dir)) {
	FILES: for my $f (  grep { m{^[a-f\d]{8}(\.\d+)?$} } readdir($dh) ) {
	    open( my $fh,'<',"$dir/$f") or next;
	    while (<$fh>) {
		m{^-+BEGIN (X509 |TRUSTED |)CERTIFICATE-} or next;
		$usable_ca{SSL_ca_path} = $dir;
		last FILES;
	    }
	}
    }
    my $file = $ENV{SSL_CERT_FILE} 
	|| ( $^O =~m{vms}i ? "SSLCERTS:cert.pem":"$openssldir/cert.pem" );
    if ( open(my $fh,'<',$file)) {
	while (<$fh>) {
	    m{^-+BEGIN (X509 |TRUSTED |)CERTIFICATE-} or next;
	    $usable_ca{SSL_ca_file} = $file;
	    last;
	}
    }
}

my $xt = prompt( "Should I do external tests?\n".
    "These test will detect if there are network problems and fail soft,\n".
    "so please disable them only if you definitely don't want to have any\n".
    "network traffic to external sites.   ".
    "[Y/n]", 'y' );


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME' => 'cPanel::IO::Socket::SSL',
    'ABSTRACT' => 'Compilable, nearly transparent SSL encapsulation for IO::Socket::INET.',
    'AUTHOR' => 'cPanel Inc, Steffen Ullrich <sullr@cpan.org>, Peter Behroozi, Marko Asplund',
    'LICENSE' => 'perl',
    'DISTNAME' => 'cPanel-IO-Socket-SSL',
    'VERSION_FROM' => 'lib/cPanel/IO/Socket/SSL.pm',
    'PREREQ_PM' => {
	'Net::SSLeay' => 1.46,
	'Scalar::Util' => 0,
	! %usable_ca ? ( 'Mozilla::CA' => 0 ):(),
    },
    'dist' => { COMPRESS => 'gzip', SUFFIX => 'gz', },
    $xt =~m{^y}i ? ( test => { TESTS => 't/*.t t/external/*.t' }):(),
    $ExtUtils::MakeMaker::VERSION >= 6.46 ? (
	'META_MERGE' => {
	    resources => {
		license     => 'http://dev.perl.org/licenses/',
		repository  => 'https://github.com/rurban/cPanel-IO-Socket-SSL',
		homepage    => 'https://github.com/rurban/cPanel-IO-Socket-SSL',
		bugtracker  => 'https://rt.cpan.org/Dist/Display.html?Queue=cPanel-IO-Socket-SSL',
	    },
	},
    ):(),
    SIGN => 1
);
