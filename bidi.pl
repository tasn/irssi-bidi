#
# BiDi support for irssi.
#
# This is useful for people that don't have BiDi "support" in their terminals,
# but still need to be able to read BiDi text like Hebrew and Arabic.
#
# It works best with themes that use %| to separate the nick from the actual
# msg.
# For example: msgnick = "%K<%n$0$1-%K>%n %|";
# This script will most likely improve in the future, feel free to send me
# patches.
#
# It's not yet perfect, but it is usable, see TODO at the bottom for more info.
#
# Also, it currently opens a new process for every line printed on screen
# that includes rtl characters (might be slow, but for me it isn't).
#
# Only works if term_charset is utf8, so "/set term_charset UTF-8".
#
# This script depends on "fribidi" (executable) being installed on the system,
# and depends on IPC::Open2 which may not work on non POSIX systems.
#
# TODO:
# * Make it work for the input line as well.
# * Fix long line wrapping handling.
# * Use libfribidi instead of the fribidi executable.

use utf8;
use Encode;
use Irssi;
use FileHandle;
use IPC::Open2;
use vars qw($VERSION %IRSSI);

$VERSION = "0.01";
%IRSSI = (
    authors     => "Tom \'TAsn\' Hacohen",
    contact     => "tom\@stosb.com",
    name        => "bidi",
    description => "BiDi support for irssi.",
    license     => "BSD",
    url         => "http://www.stosb.com/",
    changed     => "Tue Aug 28 18:51:00 IST 2012"
);

sub UNLOAD {
    #do something
}

sub string_has_rtl ($) {
   my $text = shift;
   # return if there are no bidi chars
   Encode::_utf8_on($text);

   return ($text =~ /\p{Bc=R}/);
}

sub do_bidi ($) {
   my $text = shift;
   my $ret = $text;
   $pid = open2(*Reader, *Writer, "fribidi --nopad --nobreak -") || return $ret;
   print Writer $text;
   close(Writer);
   $ret = <Reader>;
   close(Reader);
   waitpid($pid, 0);
   return $ret;
}

sub sig_printtext {
    my ($dest, $text, $stripped) = @_;

    if (string_has_rtl($stripped))
    {
        # irssi's %|
        my @split_text = split(chr(4) . "e", $text, 2);
        my $arr_len = @split_text;
        if ($arr_len == 2) {
            $text = $split_text[0] . do_bidi($split_text[1]);
        }
        else {
            # If we don't get here it's actually an error, probably usage of an
            # inocmpatible theme. Anyhow, lets try to bidi anyway...
            $text = do_bidi($text);
        }

        Irssi::signal_continue($dest, $text, $stripped);
    }
}

Irssi::signal_add('print text', 'sig_printtext');

# vim:set ts=4 sw=4 et:
