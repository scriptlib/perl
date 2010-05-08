package NightGun::Debug;
use Exporter;
our @ISA=qw/Exporter/;
our @EXPORT=qw/&message &warn &error &say &dump/;
		use Term::ANSIColor;
		use Data::Dumper;
		use constant {
			WARN_COLOR=>color('yellow'),
			MSG_COLOR=>color('green'),
			ERR_COLOR=>color('red'),
			NO_COLOR=>color('reset'),
			HD_COLOR=>color('bold'),
		};
		sub _build_hd {
			my $hd =shift;
			$hd = $hd ? "NightGun::$hd>" : "NightGun>";
		}
		sub message {
			no warnings;
			my $hd=shift;$hd = _build_hd($hd);
			print STDERR HD_COLOR,$hd,NO_COLOR,MSG_COLOR,@_,NO_COLOR,"\n";
		}
		sub warn {
			no warnings;
			my $hd=shift;$hd = _build_hd($hd);
			print STDERR HD_COLOR,$hd,NO_COLOR,WARN_COLOR,@_,NO_COLOR,"\n";
		}
		sub error {
			no warnings;
			my $hd=shift;$hd = _build_hd($hd);
			print STDERR HD_COLOR,$hd,ERR_COLOR,@_,NO_COLOR,"\n";
		}
		sub say {
			my $hd=shift;$hd = _build_hd($hd);
			print STDERR HD_COLOR,$hd,NO_COLOR,@_,NO_COLOR,"\n";
		}
		sub dump {
			print STDERR Data::Dumper->Dump(@_);  
		}
	1;
