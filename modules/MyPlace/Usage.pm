package MyPlace::Usage;
sub PrintMan {
    require Pod::Usage;
    Pod::Usage::pod2usage(-exitval=>0,-verbose => 2);
}
sub PrintHelp
{ 
    require Pod::Usage;
    Pod::Usage::pod2usage(-exitval=>0,-verbose => 1);
}

sub PrintUsage 
{
    require Pod::Usage;
    Pod::Usage::pod2usage(-exitval=>0,-verbose => 0);
}

sub PrintVersion 
{
    print STDERR join(" ",$0,@_),"\n";
}

sub Edit 
{
    system('editor', '--', $0) == 0;
}

sub Process
{
    my $opts = shift;
    my $version = shift;
    if    ($opts->{'help'})    { &PrintHelp;    exit 0; }
    elsif ($opts->{'version'}) { &PrintVersion($version); exit 0; }
    elsif ($opts->{'manual'})  { &PrintMan; exit 0; }
    elsif ($opts->{'edit-me'}) { &Edit;    exit 0; }
}
1;
