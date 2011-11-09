#!perl
# vim:ts=4:sw=4:expandtab
# !NO_I3_INSTANCE! will prevent complete-run.pl from starting i3
#
# Checks that the bar config is parsed correctly.
#

use i3test;

#####################################################################
# test a config without any bars
#####################################################################

my $config = <<EOT;
# i3 config file (v4)
font -misc-fixed-medium-r-normal--13-120-75-75-C-70-iso10646-1
EOT

my $pid = launch_with_config($config);

my $i3 = i3(get_socket_path(0));
my $bars = $i3->get_bar_config()->recv;
is(@$bars, 0, 'no bars configured');

exit_gracefully($pid);

#####################################################################
# now provide a simple bar configuration
#####################################################################

$config = <<EOT;
# i3 config file (v4)
font -misc-fixed-medium-r-normal--13-120-75-75-C-70-iso10646-1

bar {
    # Start a default instance of i3bar which provides workspace buttons.
    # Additionally, i3status will provide a statusline.
    status_command i3status --foo
}
EOT

$pid = launch_with_config($config);

$i3 = i3(get_socket_path(0));
$bars = $i3->get_bar_config()->recv;
is(@$bars, 1, 'one bar configured');

my $bar_id = shift @$bars;

my $bar_config = $i3->get_bar_config($bar_id)->recv;
is($bar_config->{status_command}, 'i3status --foo', 'status_command correct');
ok(!$bar_config->{verbose}, 'verbose off by default');
ok($bar_config->{workspace_buttons}, 'workspace buttons enabled per default');
is($bar_config->{mode}, 'dock', 'dock mode by default');
is($bar_config->{position}, 'bottom', 'position bottom by default');

#####################################################################
# ensure that reloading cleans up the old bar configs
#####################################################################

cmd 'reload';
$bars = $i3->get_bar_config()->recv;
is(@$bars, 1, 'still one bar configured');

exit_gracefully($pid);

#####################################################################
# validate a more complex configuration
#####################################################################

$config = <<EOT;
# i3 config file (v4)
font -misc-fixed-medium-r-normal--13-120-75-75-C-70-iso10646-1

bar {
    # Start a default instance of i3bar which provides workspace buttons.
    # Additionally, i3status will provide a statusline.
    status_command i3status --bar

    output HDMI1
    output HDMI2

    tray_output LVDS1
    tray_output HDMI2
    position top
    mode dock
    font Terminus
    workspace_buttons no
    verbose yes
    socket_path /tmp/foobar

    colors {
        background #ff0000
        statusline   #00ff00

        focused_workspace   #ffffff #285577
        active_workspace    #888888 #222222
        inactive_workspace  #888888 #222222
        urgent_workspace    #ffffff #900000
    }
}
EOT

$pid = launch_with_config($config);

$i3 = i3(get_socket_path(0));
$bars = $i3->get_bar_config()->recv;
is(@$bars, 1, 'one bar configured');

$bar_id = shift @$bars;

$bar_config = $i3->get_bar_config($bar_id)->recv;
is($bar_config->{status_command}, 'i3status --bar', 'status_command correct');
ok($bar_config->{verbose}, 'verbose on');
ok(!$bar_config->{workspace_buttons}, 'workspace buttons disabled');
is($bar_config->{mode}, 'dock', 'dock mode');
is($bar_config->{position}, 'top', 'position top');
is_deeply($bar_config->{outputs}, [ 'HDMI1', 'HDMI2' ], 'outputs ok');
is($bar_config->{tray_output}, 'HDMI2', 'tray_output ok');
is($bar_config->{font}, 'Terminus', 'font ok');
is($bar_config->{socket_path}, '/tmp/foobar', 'socket_path ok');
is_deeply($bar_config->{colors},
    {
        background => '#ff0000',
        statusline => '#00ff00',
        focused_workspace_text => '#ffffff',
        focused_workspace_bg => '#285577',
        active_workspace_text => '#888888',
        active_workspace_bg => '#222222',
        inactive_workspace_text => '#888888',
        inactive_workspace_bg => '#222222',
        urgent_workspace_text => '#ffffff',
        urgent_workspace_bg => '#900000',
    }, 'colors ok');

exit_gracefully($pid);

#####################################################################
# ensure that multiple bars get different IDs
#####################################################################

$config = <<EOT;
# i3 config file (v4)
font -misc-fixed-medium-r-normal--13-120-75-75-C-70-iso10646-1

bar {
    # Start a default instance of i3bar which provides workspace buttons.
    # Additionally, i3status will provide a statusline.
    status_command i3status --bar

    output HDMI1
}

bar {
    output VGA1
}
EOT

$pid = launch_with_config($config);

$i3 = i3(get_socket_path(0));
$bars = $i3->get_bar_config()->recv;
is(@$bars, 2, 'two bars configured');
isnt($bars->[0], $bars->[1], 'bar IDs are different');

my $bar1_config = $i3->get_bar_config($bars->[0])->recv;
my $bar2_config = $i3->get_bar_config($bars->[1])->recv;

isnt($bar1_config->{outputs}, $bar2_config->{outputs}, 'outputs different');

exit_gracefully($pid);

#####################################################################
# make sure comments work properly
#####################################################################

$config = <<EOT;
# i3 config file (v4)
font -misc-fixed-medium-r-normal--13-120-75-75-C-70-iso10646-1

bar {
    # Start a default instance of i3bar which provides workspace buttons.
    # Additionally, i3status will provide a statusline.
    status_command i3status --bar
    #status_command i3status --qux
#status_command i3status --qux

    output HDMI1
    colors {
        background #000000
        #background #ffffff
    }
}
EOT

$pid = launch_with_config($config);

$i3 = i3(get_socket_path(0));
$bars = $i3->get_bar_config()->recv;
$bar_id = shift @$bars;

$bar_config = $i3->get_bar_config($bar_id)->recv;
is($bar_config->{status_command}, 'i3status --bar', 'status_command correct');
is($bar_config->{colors}->{background}, '#000000', 'background color ok');

exit_gracefully($pid);

done_testing;