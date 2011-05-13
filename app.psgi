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
   my $res = Plack::Response->new( 404
                                 , [ 'Content-Type' => $config->{content_type}]
                                 );

   # build out all possible combinations of the file that we want to look for but only keep the first match
   my ($file) = grep{ -f $_ }                                                 # 6: only keep the ones that exist on the file system
                grep{ !m{/\.} }                                               # 5: drop such silly paths as ./site/.md         
                map { my $core = $_; 
                      map{ my $file = join '/', $config->{root}, $core.$_;    # 3: create all combinations of path/404 and assumed_ext
                           $file =~ s{//}{/} while $file =~ m{//};            # 4: clean up // paths
                           $file;
                         } '', @{$config->{assumed_ext}}                      # 2: take the raw path and all assumed_ext's
                    } $req->path, 404;                                        # 1: for our path and '404'

   my $content = read_file($file);
   $content = markdown($content) if $file =~ m/\.md$/;
   $res->body( sprintf $config->{template}, $content);

   return $res->finalize;
};

__DATA__
<html>
<head>
</head>
<body>
%s
</body>
</html>

