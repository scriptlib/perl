package MyPlace::Debug;
BEGIN {
    use Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $MyPlace::Debug::VERSION        = 1.00;
    @ISA            = qw(Exporter);
	@EXPORT			= qw(&debug_log);
    @EXPORT_OK      = qw(&to_string &debug_log);
}
use strict;


sub scalar_to_string {
	return $_[0] ? $_[0] =~ m/^\d+$/ ? $_[0] : "\"$_[0]\"" : "undef";
}

sub to_string {
	my $var = shift(@_);
	my $name = shift(@_) || "";
	my $tabsize = shift(@_) || 0;
	my $tabtype = shift(@_) || " ";
	my $ignorexp = shift(@_);
	my $suffix = shift(@_) || "";
	my $tab = $tabtype x $tabsize;
	my $type = ref $var;
	my $output = "$tab$name";
	if(defined($ignorexp) && $name =~ m/$ignorexp/i) {
		$output .= $tab . &scalar_to_string("<IGNORED>") . $suffix . "\n";
	}
	elsif($type eq 'ARRAY') {
		my $count = @$var;
		my $index = 0;
		$output .= "\n$tab\[\n";
		foreach(@$var) {
			$index++;
			if($count > 1 && $index<$count) {
				$output .= to_string($_,undef,$tabsize+1,$tabtype,$ignorexp,",");
			}
			else {
				$output .= to_string($_,undef,$tabsize+1,$tabtype,$ignorexp,"");
			}
		}
		$output .= "$tab\]\n";
	}
	elsif($type eq 'HASH') {
		$output .= "\n$tab\{\n";
		my $count = keys %$var;
		my $index = 0;
		foreach my $key (keys %$var) {
			$index++;
			if($count >1 && $index<$count) {
				$suffix=",";
			}
			else {
				$suffix = "";
			}
			if(defined($ignorexp) and $key =~ m/$ignorexp/) {
				$output .= to_string("IGNORED","\"$key\" : ",$tabsize+1,$tabtype,$ignorexp,$suffix);
			}
			else {
				$output .= to_string($var->{$key},"\"$key\" : ",$tabsize+1,$tabtype,$ignorexp,$suffix);
			}
		}
		$output .= "$tab\}\n";
	}
	else {
		$output .= $tab . &scalar_to_string($var) . $suffix . "\n";
	}
	return $output;
}

sub debug_log {
	require Data::Dumper;
	open FO,">","DEBUGLOG_" . time() . ".log";
	print FO Data::Dumper::Dumper([\@_],['$INFO']),"\n";
	close FO;
	return @_;
}
1;
