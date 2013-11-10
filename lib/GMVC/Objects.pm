use strictures 1;

package GMVC::Objects;
use Module::Runtime qw( use_module );

use namespace::clean;
use Exporter 'import';

our @EXPORT_OK = qw(
    object
    object_direct
    object_connect
    object_connect_after
    call_method
);

sub call_method {
    my ($object, $method, @args) = @_;
    return $object->$method(@args);
}

my $_connect = sub {
    my ($via, $object, $signals) = @_;
    for my $signal (keys %$signals) {
        my $value = $signals->{ $signal };
        my @actions = ((ref($value) eq 'ARRAY') ? @$value : $value);
        for my $action (@actions) {
            $object->$via($signal, $action);
        }
    }
    return 1;
};

sub object_connect { signal_connect->$_connect(@_) }
sub object_connect_after { signal_connect_after->$_connect(@_) }

sub object_direct {
    my ($class, $spec, $other) = @_;
    die "Missing class name for object creation\n"
        unless defined $class;
    $spec = {}
        unless defined $spec;
    $other = {}
        unless defined $other;
    die join ' ',
        "Property specification for $class instance",
        "is not a hash reference\n",
        unless ref $spec eq 'HASH';
    use_module($class)
        unless $class->can('new');
    return $class->new(%$spec, %$other);
}

sub object {
    my ($class, $spec) = @_;
    die "Missing class name for object creation\n"
        unless defined $class;
    $spec = {}
        unless defined $spec;
    $spec = { construct => $spec }
        unless ref $spec eq 'HASH';
    my %left = %$spec;
    my $constructor = delete $left{constructor} || 'new';
    my $construct = delete $left{construct};
    $construct = {}
        unless defined $construct;
    my $set = delete $left{set};
    my @construct_args =
        (ref $construct eq 'HASH') ? %$construct
      : (ref $construct eq 'ARRAY') ? @$construct
      : die "Option 'construct' has to be array or hash reference\n";
    my $calls = delete $left{call};
    die sprintf "Invalid instance creation options: %s\n",
        join ', ', keys %left,
        if keys %left;
    $set = {}
        unless defined $set;
    use_module($class)
        unless $class->can('new');
    my $object = $class->$constructor(@construct_args);
    $object->set(%$set)
        if keys %$set;
    for my $call (@$calls) {
        my ($method, @method_args) = @$call;
        $object->$method(@method_args);
    }
    return $object;
}

1;
