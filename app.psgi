use Data::Dumper; sub DUMP (@) {Dumper(@_)}; sub D (@_){print Dump @_};
use Plack::Response;
use Plack::Request;
use File::Slurp;
use Text::Markdown qw{markdown};

my $config = { root         => './site'
             , content_type => 'text/html'
             , assumed_ext  => [qw{.html /index.html .md /index.md}] # order matters
             , template     => '' # build below because I'm lazy
             };
# I'm lazy, sluping <DATA> you'll likley want to have this as some file somewhere
{ local $/=undef;
  $config->{template} = <DATA>;
};

my $app = sub {
   my $req = Plack::Request->new(shift);
   my $file = 
   return $req->path =~ m{/edit$}
        ? edit($req)
        : display($req);

};
sub find_file {
   # build out all possible combinations of the file that we want to look for but only keep the first match
   my ($file) = grep{ -f $_ }                                                 # 6: only keep the ones that exist on the file system
                grep{ !m{/\.} }                                               # 5: drop such silly paths as ./site/.md         
                map { my $core = $_; 
                      map{ my $file = join '/', $config->{root}, $core.$_;    # 3: create all combinations of path/404 and assumed_ext
                           $file =~ s{//}{/} while $file =~ m{//};            # 4: clean up // paths
                           $file;
                         } '', @{$config->{assumed_ext}}                      # 2: take the raw path and all assumed_ext's
                    } @_ ;                                                    # 1: for all given 'core's (ie @_)
   return $file;
}


sub edit {
   my $req    = shift;
   my ($path) = $req->path =~ m{(.*)/edit};
   my $file   = find_file($path) || $path =~ m/\.\w+/ ? $path : $path.'.md'; #attempt to find an existing file, if not assume the path as the desired file
   my $res    = Plack::Response->new( 200
                                    , [ 'Content-Type' => $config->{content_type}]
                                    , sprintf q{YOU WANT TO EDIT %s AT PATH %s}, $file, $path
                                    );
   return $res->finalize;
}
  

sub display {
   my $req = shift;
   my $res = Plack::Response->new( 404
                                 , [ 'Content-Type' => $config->{content_type}]
                                 );
   my $file = find_file($req->path, 404);
   my $content = read_file($file);
   $content = markdown($content) if $file =~ m/\.md$/;
   $res->body( sprintf $config->{template}, $content);
   return $res->finalize;
}

__DATA__
<html>
<head>
</head>
<body>
%s
</body>
</html>

