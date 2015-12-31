#!/usr/bin/perl -w
package MyPlace::Curl;
use strict;
use warnings;
BEGIN {
#    sub debug_print {
#        return unless($ENV{XR_PERL_MODULE_DEBUG});
#        print STDERR __PACKAGE__," : ",@_;
#    }
#    &debug_print("BEGIN\n");
    require Exporter;
    our ($VERSION,@ISA,@EXPORT,@EXPORT_OK,%EXPORT_TAGS);
    $VERSION        = 1.00;
    @ISA            = qw(Exporter);
    @EXPORT         = qw();
    @EXPORT_OK      = qw();
}
my @CURL = qw/curl/;
my @CURLOPT = (
            'globoff'		=>'',
            'progress-bar'	=>'',
            'create-dirs'	=>'',
            'connect-timeout'=>15,
			'user-agent'=>'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008092416 Firefox/3.0.3 Firefox/3.0.1',
);
my $PROXY = '127.0.0.1:9050';
my $BLOCKED_HOST = 'wretch\.cc|facebook\.com|fbcdn\.net';
my $BLOCKED_EXP = qr/^[^\/]+:\/\/[^\/]*(?:$BLOCKED_HOST)(?:\/?|\/.*)$/;

my %CURL_EXIT = (
    1=>'Unsupported protocol',
    2=>'Failed to initialize',
    3=>'URL malformed',
    5=>'Couldn\'t resolve proxy',
    6=>'Couldn\'t resolve host',
    7=>'Failed to connect to host',
    8=>'FTP weird server reply',
    9=>'FTP access denied',
    10=>'directory that doesn\'t exist on the server',
    11=>'FTP weird PASS reply',
    13=>'FTP weird PASV reply, Curl couldn\'t parse the reply sent to the PASV request',
    14=>'FTP weird 227 format',
    15=>'FTP can\'t get host',
    17=>'FTP couldn\'t set binary',
    18=>'Partial file',
    19=>'FTP couldn\'t download/access the given file, the RETR (or similar) command failed',
    21=>'FTP quote error',
    22=>'HTTP  page  not retrieved',
    23=>'Write error',
    25=>'FTP couldn\'t STOR file',
    26=>'Read error',
    27=>'Out of memory',
    28=>'Operation timeout',
    30=>'FTP PORT failed',
    31=>'FTP couldn\'t use REST',
    33=>'HTTP range error',
    34=>'HTTP post error',
    35=>'SSL connect error',
    36=>'FTP bad download resume',
    37=>'FILE couldn\'t read file',
    38=>'LDAP cannot bind',
    39=>'LDAP search failed',
    41=>'Function not found',
    42=>'Aborted by callback',
    43=>'Internal error',
    45=>'Interface error',
    47=>'Too many redirects',
    48=>'Unknown TELNET option specified',
    49=>'Malformed telnet option',
    51=>'The peer\'s SSL certificate or SSH MD5 fingerprint was not ok',
    52=>'The server didn\'t reply anything, which here is considered an error',
    53=>'SSL crypto engine not found',
    54=>'Cannot set SSL crypto engine as default',
    55=>'Failed sending network data',
    56=>'Failure in receiving network data',
    58=>'Problem with the local certificate',
    59=>'Couldn\'t use specified SSL cipher',
    60=>'Peer certificate cannot be authenticated with known CA certificates',
    61=>'Unrecognized transfer encoding',
    62=>'Invalid LDAP URL',
    63=>'Maximum file size exceeded',
    64=>'Requested FTP SSL level failed',
    65=>'Sending the data requires a rewind that failed',
    66=>'Failed to initialise SSL Engine',
    67=>'The user name, password, or similar was not accepted and curl failed to log in',
    68=>'File not found on TFTP server',
    69=>'Permission problem on TFTP server',
    70=>'Out of disk space on TFTP server',
    71=>'Illegal TFTP operation',
    72=>'Unknown TFTP transfer ID',
    73=>'File already exists (TFTP)',
    74=>'No such user (TFTP)',
    75=>'Character conversion failed',
    76=>'Character conversion functions required',
    77=>'Problem with reading the SSL CA cert (path? access rights?)',
    78=>'The resource referenced in the URL does not exist',
    79=>'An unspecified error occurred during the SSH session',
    80=>'Failed to shut down the SSL connection',
    82=>'Could not load CRL file, missing or wrong format',
    83=>'Issuer check failed',
);
#my %HTTP_STATUS = (
#    100=>'Continue',
#    101=>'Switching Protocols',
#    102=>'Processing (WebDAV) (RFC 2518)',
#    200=>'Successful',
#    201=>'Created',
#    202=>'Accepted',
#    203=>'Non-authoritative information',
#    204=>'No content',
#    205=>'Reset content',
#    206=>'Partial content',
#    300=>'Multiple choices',
#    301=>'Moved permanently',
#    302=>'Moved temporarily',
#    303=>'See other location',
#    304=>'Not modified',
#    305=>'Use proxy',
#    307=>'Temporary redirect',
#    400=>'Bad request',
#    401=>'Not authorized',
#    403=>'Forbidden',
#    404=>'Not found',
#    405=>'Method not allowed',
#    406=>'Not acceptable',
#    407=>'Proxy authentication required',
#    408=>'Request timeout',
#    409=>'Conflict',
#    410=>'Gone',
#    411=>'Length required',
#    412=>'Precondition failed',
#    413=>'Request entity too large',
#    414=>'Requested URI is too long',
#    415=>'Unsupported media type',
#    416=>'Requested range not satisfiable',
#    417=>'Expectation failed',
#    500=>'Internal server error',
#    501=>'Not implemented',
#    502=>'Bad gateway',
#    503=>'Service unavailable',
#    504=>'Gateway timeout',
#    505=>'HTTP version not supported',
#);

sub error_message
{
    my $self = shift;
    my $status_code = shift;
    return $CURL_EXIT{$status_code} ? $CURL_EXIT{$status_code} : "Unknown error";
}

sub new {
    my $class = shift;
    my $self = bless {},$class;
    $self->{options} = {@CURLOPT,@_};
    return $self;
}
sub set {
    my $self = shift;
    my $name = shift;
    my $value = shift;
    $self->{options}->{$name} = $value;
}

sub _build_cmd 
{
    my $self = shift;
    my @cmds;
#    my @cmds = @CURL;
    foreach(keys %{$self->{options}})
    {
        if($self->{options}->{$_}) 
        {
            push @cmds,"--$_",$self->{options}->{$_};
        }
        else
        {
            push @cmds,"--$_";
        }
    }
    return @cmds;
}

sub _run_curl 
{
    my $self = shift;
    my $decoder;
	my $utf8;
    my @args;
    foreach($self->_build_cmd,@_) {
        next unless($_);
        if(m/^charset:([^\s]+)/) {
            require Encode;
            $decoder = Encode::find_encoding($1);
			$utf8 = Encode::find_encoding('utf8');
        }
        else {
            push @args,$_;
        }
    }
#	print STDERR join(" ",@CURL,@args),"\n";
    open FI,"-|",@CURL,@args;
    my $data = join("",<FI>);
    close FI;
    if($decoder && ref $decoder) {
		$data = $utf8->encode($decoder->decode($data));

    }
    my $exit_code = $?;
    if($exit_code == 0) 
    {
    }
    elsif($exit_code & 127)
    {
        $exit_code = -1;
    }
    else
    {
        $exit_code = $exit_code>>8;
    }
    #if(-f $self->{options}{'cookie-jar'}) {
    #    system('sed','-i','-e','s/^#HttpOnly_//g',$self->{options}{'cookie-jar'});
    #}
	if(wantarray) {
		return $exit_code,$data;
	}
	else {
		return $exit_code;
	}
}

sub get {
    my $self = shift;
    my $url = shift;
    $url =~ s/&amp;/&/g;
    my @args = (@_,"--url",$url);
    push @args,'--socks5-hostname',$PROXY    if($url =~ $BLOCKED_EXP);
    return $self->_run_curl(@args);
}
sub post {
    my $self = shift;
    my $url = shift;
    my $referer = shift;
    my %posts = @_;
    return undef unless($url);


    my @args = ("--url",$url);
    push @args,'--socks5-hostname',$PROXY    if($url =~ $BLOCKED_EXP);
    push @args,"--referer",$referer if($referer);
    use URI::Escape;    

    if(%posts) 
    {
   #     push @args, "--data",join("&", map({"$_=$posts{$_}"} keys %posts));
        my $data = join("&", map({"$_=" . uri_escape($posts{$_})} keys %posts));
        push @args, "--data",$data;
        print STDERR "Posting:[$data]\nTo $url\n...";
    }
    return $self->_run_curl(@args);
}

sub print {
    my $self = shift;
    my $action = shift;
    if($action eq 'post') {
        print $self->post(@_);
    }
    else {
        print $self->get(@_);
    }
}

1;
