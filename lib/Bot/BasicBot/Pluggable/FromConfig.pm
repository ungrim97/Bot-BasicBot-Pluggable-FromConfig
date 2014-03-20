package Bot::BasicBot::Pluggable::FromConfig;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

=encoding utf-8

=head1 NAME

Bot::BasicBot::Pluggable::FromConfig - Create a bot from a config file.

=head1 SYNOPSIS

    use Bot::BasicBot::Pluggable::FromConfig;

    my $bot = Bot::BasicBot::Pluggable::FromConfig->new_with_config(
        config => {name => 'my_bot', path => 'some/path'},
    );

=head1 DESCRIPTION

Bot::BasicBot::Pluggable::FromConfig is a config loader for Bot::BasicBot::Pluggable allowing all of you Bot configuration to be declared in its own file. It is largely based on C<Bot::BasicBot::Pluggable::WithConfig>. Its designed to allow for a wider degree of flexibility with its range of accepted config files.

FromConfig uses Config::JFDI to load a config based on the name supplied to the config argument. This allows pretty much any config style you want and also allows for a '_local' file to override on a per instance bases if you need.

=head1 Running a Bot

This library provides a command line script called C<run_bot>. This provides a complete implementation of this. Documentation can be found there.

Alternatively you can create your own implementation of this in your own scripts. The simplest method is to call new_with_config() and pass it a config name and then call run on the returned Bot object.

=head1 METHODS

=head2 new_with_config( config => 'my_bot' )

This is the only method provided in this module beyond those described in L<Bot::BasicBot::Pluggable>. It accepts a hash as its arguments which must contain a config key. This key can either be the name of the config sans extension (which will be passed as the name param to Config::JFDI) or a hashref of params to pass through to Config::JFDI. 

A new Bot::BasicBot::Pluggable::FromConfig object which inherits from L<Bot::BasicBot::Pluggable> is returned.

=cut

use Config::JFDI;
use Data::Dumper;
use Carp;

use base 'Bot::BasicBot::Pluggable';

sub new_with_config {
    my ($class, %args) = @_;

    croak 'No config param supplied.' unless $args{config};

    $args{config} = {name => $args{config}} unless ref $args{config};

    my $conf = Config::JFDI->open(%{$args{config}}) or croak "Unable to load config file for: ".$args{config}.'.'.Dumper $@;

    my @plugins = @{delete $conf->{plugins} || [] };
    my $bot = $class->new(%{$conf||{}});

    for my $plugin (@plugins){
        my $module_name = $plugin->{module};
        $module_name =~ s/Bot::BasicBot::Pluggable::Module//;
        my $plugin_obj = $bot->load($module_name);

        my %config = %{$plugin->{config} || {}};
        for my $param (keys %config){
            $plugin_obj->set($param => $config{$param});
        }
    }

    return $bot;
}

1;
__END__

=head1 Config Keys

All attributes accepted by the constructor of C<Bot::BasicBot::Pluggable> and thus C<Bot::BasicBot> are valid configuration items.

=head2 plugins

A arrayref of plugins are also accepted:
    {
        "channels": ["#perl"],
        "plugins": [
            {
                "Module": 'Karma',
                "config": {
                    "karma_change_reponse": 0
                },
            },
            {
                "name": "Bot::BasicBot::Pluggable::Module::Auth",
            },
    }
each should provide at minimum the name of the Module that implements the plugin. This can either be the full qualified name (Bot::BasicBot::Pluggable::Module::Name) or just the qualifying module name.

A config hashref can also be specified and these items will be passed to the plugin objects set() method.

=head1 SEE ALSO

C<Config::JFDI>
C<Bot::BasicBot::Pluggable>

=head1 LICENSE

Copyright (C) Mike Francis.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Mike Francis E<lt>ungrim97@gmail.comE<gt>

=cut

