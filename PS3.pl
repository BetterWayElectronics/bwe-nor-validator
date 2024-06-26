#!/usr/bin/perl 

use strict;
#use warnings;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Win32::Console::ANSI;
use Term::ANSIScreen qw/:color /;
use Term::ANSIScreen qw(cls);
use Time::HiRes;
use Fcntl qw(:flock :seek);
use String::HexConvert ':all';
use Win32::Console;
use File::Copy qw(copy);
use Regexp::Assemble;

###################################

START:
use LWP::Simple qw($ua get); $ua->timeout(10); $ua->agent('BwE NOR Validator/1.31');
print "Checking for latest version...\n";
my $latest = get 'http://betterwayelectronics.com/version.txt';

my $clear_screen = cls(); print $clear_screen;
my $oldversion = (colored ['bold red'], "DANGER!");
my $noversion = (colored ['bold'], "WARNING!");

#####################################

my $version = "1.31";

###########################

print "=======================================================================\n\n";
print "                         BwE NOR Validator $version\n\n";
print "                      www.betterwayelectronics.com\n\n";
print "                           www.ps3devwiki.com\n\n";
print "=======================================================================\n\n";
open( my $latestversion, '<', \$latest ); $latest //= 'Unknown';
if ($latest eq "Unknown") {} elsif ($latest ne $version) {print "$oldversion Latest version is $latest - You are out of date! $oldversion\n\n=======================================================================\n\n";} 

####################################

my @files=(); 

while (<*.bin>) 
 {
     push (@files, $_) if (-f "$_");
 }

my $input; my $file; my $original;

if ( @files == 0 ) {
print "\nAborting: Nothing to validate\n"; goto FAILURE;
}

if ( @files > 1 ) { 
print "Multiple .bin files found within the directory:\n\n";
foreach my $file (0..$#files) {print $file + 1 . " - ", "$files[$file]\n";}
print "\nPlease make a selection: ";
my $input = <STDIN>; chomp $input; 
if ($input eq "") {print "\nAborting: You didn't select anything\n"; goto FAILURE;} else {$file = $files[$input-1]; $original = $files[$input-1];}; 
my $nums = scalar(@files); if ($input le $nums) {$file = $files[$input-1]; $original = $files[$input-1];}
} else { $file = $files[0]; $original = $file = $files[0];}


open(my $bin, "<", $file) or die $!; binmode $bin;
my $md5sum = uc Digest::MD5->new->addfile($bin)->hexdigest; my $size= -s $bin;

my $start_time = [Time::HiRes::gettimeofday()];

seek($bin, 0x40014, 0);read($bin, my $bytereversed2, 0x4); $bytereversed2 = uc ascii_to_hex($bytereversed2);
if ($bytereversed2 eq "0FACE0FF") { print "\n\nAborting: NAND - Can not validate\n\n"; goto FAILURE} else {};
if ($size ne "16777216") { print "\n\nAborting: File size is incorrect\n\n"; goto FAILURE} else {};


############################################################################################################################################
print $clear_screen;

print "=======================================================================\n\n";
print "                         BwE NOR Validator $version\n\n";
print "                      www.betterwayelectronics.com\n\n";
print "                           www.ps3devwiki.com\n\n";
print "=======================================================================\n\n";
open( my $latestversion, '<', \$latest ); $latest //= 'Unknown';
if ($latest eq "Unknown") {print "$noversion Can't find latest version!\n\n";} elsif ($latest ne $version) {print "$oldversion Latest version is $latest - You are out of date! $oldversion\n\n";} 

print "Filename: $file\n";
print "MD5: $md5sum\n";
print "File Size: $size\n\n";

seek($bin, 0x14, 0);read($bin, my $bytereversed, 0x4); $bytereversed = uc ascii_to_hex($bytereversed);

my $hexin; my $n; my $reversed;
(my $fileminusbin = $file) =~ s/\.[^.]+$//;

if (-e $fileminusbin."_swapped.bin_results.html") {print "Already opened/validated/reversed $file"; goto FAILURE;} else {
if ($bytereversed eq "AC0FFFE0") {
open(my $fin, '<', $file) or die $!; binmode($fin);
my $fileminusbin = $file =~ s/\.[^.]+$//;
open(my $fout, '+>', $file."_swapped.bin") or die $!; binmode($fout);

print "Dump is byte-reversed! (E3-Flasher)\n\nMaking $file\_swapped.bin ....\n\n"; 
$bin = $fout; $file = $file."_swapped.bin";

while (($n = read($fin, $hexin, 4)) == 4) {
    my @c = split('', $hexin);
    my $hexout = join('', $c[1], $c[0], $c[3], $c[2]);
    print $fout $hexout;
}
	
} }

############################################################################################################################################
if (-e "./Patches/patch1.bin") {} else {print "patch1.bin missing from /Patches/ folder"; goto FAILURE;};
if (-e "./Patches/patch2.bin") {} else {print "patch2.bin missing from /Patches/ folder"; goto FAILURE;};
if (-e "./Patches/patch4.bin") {} else {print "patch4.bin missing from /Patches/ folder"; goto FAILURE;};

seek($bin, 0xC0010, 0);
read($bin, my $buffer_ros0, 0x6FFFE0);
seek($bin, 0x7C0010, 0);
read($bin, my $buffer_ros1, 0x6FFFE0);
seek($bin, 0x40010, 0);
read($bin, my $buffer_TRVK_PRG0, 0xFE0);
seek($bin, 0x60010, 0);
read($bin, my $buffer_TRVK_PRG1, 0xFE0);
seek($bin, 0x80010, 0);
read($bin, my $buffer_TRVK_PKG0, 0xFE0);
seek($bin, 0xA0010, 0);
read($bin, my $buffer_TRVK_PKG1, 0xFE0);

my $ros0_convert = uc md5_hex($buffer_ros0);
my $ros1_convert = uc md5_hex($buffer_ros1);
my $TRVK_PRG0 = uc md5_hex($buffer_TRVK_PRG0);
my $TRVK_PRG1 = uc md5_hex($buffer_TRVK_PRG1);
my $TRVK_PKG0 = uc md5_hex($buffer_TRVK_PKG0);
my $TRVK_PKG1 = uc md5_hex($buffer_TRVK_PKG1);

my %three55 = map { $_ => 1 } ("FCEAC0A025F8225E523FA190B38B540C","F162E0D72EBA0F46B7FB36E6AAB63958","102E229DF047C1693ABFBFF5707BE84C","A974F88457424AC6D8E262DBF3ED7AA0","6CE56CC2BD4238E831E9A64E4547A81B","7B75FF7995C4B7841B638B27BE3674C6");

seek($bin, 0x2F077, 0);read($bin, my $idps356, 0x01); $idps356 = uc ascii_to_hex($idps356);
seek($bin, 0xFC0002, 0); read($bin, my $bootldr356, 0x02); $bootldr356 = uc ascii_to_hex($bootldr356);


if ($bootldr356 eq "301B" or $bootldr356 eq "2FFB" or $bootldr356 eq "300B") {goto NoPatch;} else {
if ($idps356 eq "0B" and $bootldr356 eq "2F5B") {goto Rogero;} else {
if (exists $three55{$ros0_convert}) {} else {
if (-e $original."_patched") {} else {

if ($bytereversed eq "AC0FFFE0") {
print "\nPatch byte-reversed (E3 Compatible) for 3.55 Downgrading? Y/N: ";
my $input = <STDIN>; chomp $input; if ($input eq "y") {

my $stuff; use Fcntl 'SEEK_SET';
my $patched = $original."_patched"; copy $original, $patched;
open (my $FIN, '+<',$patched) or die $!; binmode($FIN); binmode($FIN);

open(my $patch1, '<', "./Patches/patch1.bin") or die $!; binmode($patch1);
open(my $patch2, '<', "./Patches/patch2.bin") or die $!; binmode($patch2);

sysread ($patch1, $stuff, 0x6FFFE0);
sysseek $FIN, 0xC0010, SEEK_SET; syswrite ($FIN, $stuff);
sysseek $FIN, 0x7C0010, SEEK_SET; syswrite ($FIN, $stuff);

sysread ($patch2, $stuff, 0x80000);
sysseek $FIN, 0x40000, SEEK_SET; syswrite ($FIN, $stuff);

close ($patched);

print "\nDump has been patched as 3.55 byte-reversed ($original\_patched)\n";
} else {}}}
}
}
}

if (exists $three55{$ros0_convert}) {} else {
if ($bytereversed eq "AC0FFFE0") {} else {
if (-e $file."_patched") {print "\nAlready patched $file"; goto FAILURE;} else {
print "\nPatch swapped (Progskeet/Teensy Compatible) for 3.55 Downgrading? Y/N: ";
my $input = <STDIN>; chomp $input; if ($input eq "y") {

open(my $patch1in, '<', "./Patches/patch1.bin") or die $!; binmode($patch1in);
open(my $patch1out, '+>', "./Patches/patch1n.bin") or die $!; binmode($patch1out);

while (($n = read($patch1in, $hexin, 4)) == 4) {
    my @c = split('', $hexin);
    my $hexout = join('', $c[1], $c[0], $c[3], $c[2]);
    print $patch1out $hexout;
}
open(my $patch2in, '<', "./Patches/patch2.bin") or die $!; binmode($patch2in);
open(my $patch2out, '+>', "./Patches/patch2n.bin") or die $!; binmode($patch2out);

while (($n = read($patch2in, $hexin, 4)) == 4) {
    my @c = split('', $hexin);
    my $hexout = join('', $c[1], $c[0], $c[3], $c[2]);
    print $patch2out $hexout;
}

close ($patch1out); close ($patch2out);

my $stuff; use Fcntl 'SEEK_SET';
my $patched = $file."_patched"; copy $file, $patched;
open (my $FIN, '+<',$patched) or die $!; binmode($FIN); binmode($FIN);

open(my $patch1, '<', "./Patches/patch1n.bin") or die $!; binmode($patch1);
open(my $patch2, '<', "./Patches/patch2n.bin") or die $!; binmode($patch2);

sysread ($patch1, $stuff, 0x6FFFE0);
sysseek $FIN, 0xC0010, SEEK_SET; syswrite ($FIN, $stuff);
sysseek $FIN, 0x7C0010, SEEK_SET; syswrite ($FIN, $stuff);

sysread ($patch2, $stuff, 0x80000);
sysseek $FIN, 0x40000, SEEK_SET; syswrite ($FIN, $stuff);

close ($patch1); close ($patch2);

unlink "./Patches/patch1n.bin"; unlink "./Patches/patch2n.bin";

print "\nDump has been patched as 3.55 ($file\_patched)\n";

} else {}
}}}

Rogero:
if (exists $three55{$ros0_convert}) {} else {
if (-e $original."_patched") {} else {
if ($bytereversed eq "AC0FFFE0") {
print "\nPatch byte-reversed (E3 Compatible) for 4.40 No-FSM Downgrading? Y/N: ";
my $input = <STDIN>; chomp $input; if ($input eq "y") {

my $stuff; use Fcntl 'SEEK_SET';
my $patched = $original."_patched"; copy $original, $patched;
open (my $FIN, '+<',$patched) or die $!; binmode($FIN); binmode($FIN);

open(my $patch1, '<', "./Patches/patch4.bin") or die $!; binmode($patch1);

sysread ($patch1, $stuff, 0x6FFFE0);
sysseek $FIN, 0xC0010, SEEK_SET; syswrite ($FIN, $stuff);
sysseek $FIN, 0x7C0010, SEEK_SET; syswrite ($FIN, $stuff);

close ($patched);

print "\nDump has been patched as 4.40 byte-reversed ($original\_patched)\n";
} else {}}}

if ($bytereversed eq "AC0FFFE0") {} else {
if (-e $original."_patched") {} else {
print "\nPatch swapped (Progskeet/Teensy Compatible) for 4.40 No-FSM Downgrading? Y/N: ";
my $input = <STDIN>; chomp $input; if ($input eq "y") {

open(my $patch1in, '<', "./Patches/patch4.bin") or die $!; binmode($patch1in);
open(my $patch1out, '+>', "./Patches/patch4n.bin") or die $!; binmode($patch1out);

while (($n = read($patch1in, $hexin, 4)) == 4) {
    my @c = split('', $hexin);
    my $hexout = join('', $c[1], $c[0], $c[3], $c[2]);
    print $patch1out $hexout;
}

close ($patch1out);

my $stuff; use Fcntl 'SEEK_SET';
my $patched = $file."_patched"; copy $file, $patched;
open (my $FIN, '+<',$patched) or die $!; binmode($FIN); binmode($FIN);

open(my $patch1, '<', "./Patches/patch4n.bin") or die $!; binmode($patch1);

sysread ($patch1, $stuff, 0x6FFFE0);
sysseek $FIN, 0xC0010, SEEK_SET; syswrite ($FIN, $stuff);
sysseek $FIN, 0x7C0010, SEEK_SET; syswrite ($FIN, $stuff);

close ($patch1); 

unlink "./Patches/patch4n.bin"; 

print "\nDump has been patched as 4.40 ($file\_patched)\n";

} else {}
}}}

# ########################################
# Musketeer:

# if (exists $three55{$ros0_convert}) {} else {
# if ($idps356 eq "0B" and $bootldr356 eq "2F5B") {
# if (-e $original."_patched") {} else {

# if ($bytereversed eq "AC0FFFE0") {
# print "\nPatch byte-reversed (E3 Compatible) for 3.56 Downgrading? Y/N: ";
# my $input = <STDIN>; chomp $input; if ($input eq "y") {

# my $stuff; use Fcntl 'SEEK_SET';
# my $patched = $original."_patched"; copy $original, $patched;
# open (my $FIN, '+<',$patched) or die $!; binmode($FIN); binmode($FIN);

# open(my $patch31, '<', "./Patches/patch3.1.bin") or die $!; binmode($patch31);
# open(my $patch32, '<', "./Patches/patch3.2.bin") or die $!; binmode($patch32);
# open(my $patch33, '<', "./Patches/patch3.3.bin") or die $!; binmode($patch32);

# sysread ($patch31, $stuff, 0x6FFFE0);
# sysseek $FIN, 0xC0010, SEEK_SET; syswrite ($FIN, $stuff);
# sysseek $FIN, 0x7C0010, SEEK_SET; syswrite ($FIN, $stuff);

# sysread ($patch32, $stuff, 0x20000);
# sysseek $FIN, 0x80000, SEEK_SET; syswrite ($FIN, $stuff);
# sysseek $FIN, 0xA0000, SEEK_SET; syswrite ($FIN, $stuff);

# sysread ($patch33, $stuff, 0x20000);
# sysseek $FIN, 0x40000, SEEK_SET; syswrite ($FIN, $stuff);
# sysseek $FIN, 0x60000, SEEK_SET; syswrite ($FIN, $stuff);

# close ($patched);

# print "\nDump has been patched as 3.56 '3 Musketeers' byte-reversed ($original\_patched)\n";
# } else {}}}

# if (-e $file."_patched") {print "\nAlready patched $file"; goto FAILURE;} else {
# print "\nPatch swapped (Progskeet/Teensy Compatible) for 3.56 -> 4.30 CFW? Y/N: ";
# my $input = <STDIN>; chomp $input; if ($input eq "y") {

# open(my $patch31in, '<', "./Patches/patch3.1.bin") or die $!; binmode($patch31in);
# open(my $patch31out, '+>', "./Patches/patch3.1n.bin") or die $!; binmode($patch31out);

# while (($n = read($patch31in, $hexin, 4)) == 4) {
    # my @c = split('', $hexin);
    # my $hexout = join('', $c[1], $c[0], $c[3], $c[2]);
    # print $patch31out $hexout;
# }
# open(my $patch32in, '<', "./Patches/patch3.2.bin") or die $!; binmode($patch32in);
# open(my $patch32out, '+>', "./Patches/patch3.2n.bin") or die $!; binmode($patch32out);

# while (($n = read($patch32in, $hexin, 4)) == 4) {
    # my @c = split('', $hexin);
    # my $hexout = join('', $c[1], $c[0], $c[3], $c[2]);
    # print $patch32out $hexout;
# }
# open(my $patch33in, '<', "./Patches/patch3.3.bin") or die $!; binmode($patch33in);
# open(my $patch33out, '+>', "./Patches/patch3.3n.bin") or die $!; binmode($patch33out);

# while (($n = read($patch33in, $hexin, 4)) == 4) {
    # my @c = split('', $hexin);
    # my $hexout = join('', $c[1], $c[0], $c[3], $c[2]);
    # print $patch33out $hexout;
# }
# close ($patch31out); close ($patch32out); close ($patch33out);

# my $stuff; use Fcntl 'SEEK_SET';
# my $patched = $file."_patched"; copy $file, $patched;
# open (my $FIN, '+<',$patched) or die $!; binmode($FIN); binmode($FIN);

# open(my $patch31, '<', "./Patches/patch3.1n.bin") or die $!; binmode($patch31);
# open(my $patch32, '<', "./Patches/patch3.2n.bin") or die $!; binmode($patch32);
# open(my $patch33, '<', "./Patches/patch3.3n.bin") or die $!; binmode($patch33);

# sysread ($patch31, $stuff, 0x6FFFE0);
# sysseek $FIN, 0xC0010, SEEK_SET; syswrite ($FIN, $stuff);
# sysseek $FIN, 0x7C0010, SEEK_SET; syswrite ($FIN, $stuff);

# sysread ($patch32, $stuff, 0x20000);
# sysseek $FIN, 0x80000, SEEK_SET; syswrite ($FIN, $stuff);
# sysseek $FIN, 0xA0000, SEEK_SET; syswrite ($FIN, $stuff);

# sysread ($patch33, $stuff, 0x20000);
# sysseek $FIN, 0x40000, SEEK_SET; syswrite ($FIN, $stuff);
# sysseek $FIN, 0x60000, SEEK_SET; syswrite ($FIN, $stuff);


# close ($patch31); close ($patch32); close ($patch33);

# unlink "./Patches/patch3.1n.bin"; unlink "./Patches/patch3.2n.bin"; unlink "./Patches/patch3.3n.bin"; 

# print "\nDump has been patched as 3.56 '3 Musketeers' ($file\_patched)\n";

# } else {}
# }
# }

NoPatch:

if ($bytereversed eq "0FACE0FF") {
print "\nByte-reverse original for experimental purposes? Y/N: ";
my $input = <STDIN>; chomp $input; if ($input eq "y") {
open(my $fin, '<', $file) or die $!; binmode($fin);
open(my $fout, '+>', $file."_reversed.bin") or die $!; binmode($fout);

while (($n = read($fin, $hexin, 4)) == 4) {
    my @c = split('', $hexin);
    my $hexout = join('', $c[1], $c[0], $c[3], $c[2]);
    print $fout $hexout;
}
print "\nDump has been byte-reversed ($file\_reversed.bin)\n"; 
}
} 
#}

############################################################################################################################################

open(F,'>', $file."_results.html") || die $!;

print F q{

<!doctype html>
<html>
	<head>
		<meta charset="utf-8">
				<title>BwE NOR Validator - HTML Output Edition</title>

<style class="cssdeck">body {
  font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
  padding: 20px 50px 150px;
  font-size: 12px;
  text-align: left;
}
html { 
	background: url(http://i.imgur.com/TAi5Xod.jpg) no-repeat center center fixed; 
	-webkit-background-size: cover;
	-moz-background-size: cover;
	-o-background-size: cover;
	background-size: cover;
}
ul {
  text-align: left;
  display: inline;
  margin: 0;
  padding: 15px 4px 17px 0;
  list-style: none;
  -webkit-box-shadow: 0 0 5px rgba(0, 0, 0, 0.15);
  -moz-box-shadow: 0 0 5px rgba(0, 0, 0, 0.15);
  box-shadow: 0 0 5px rgba(0, 0, 0, 0.15);
}
ul li {
  font: bold 12px/18px sans-serif;
  display: inline-block;
  margin-right: -4px;
  position: relative;
  padding: 15px 20px;
  background: #A4A4A4;
  cursor: pointer;
  -webkit-transition: all 0.2s;
  -moz-transition: all 0.2s;
  -ms-transition: all 0.2s;
  -o-transition: all 0.2s;
  transition: all 0.2s;
}

ul li:hover {background: #555;color: #fff;}
ul a:link {font-size: 12px;font-weight: 500;color: #fff;}

a:link {color:#A4A4A4;}      /* unvisited link */
a:visited {color:#A4A4A4;}  /* visited link */
a:hover {color:#A4A4A4;}  /* mouse over link */
a:active {color:#A4A4A4;}  /* selected link */ 

ul a:visited {color: #fff;}
ul a:hover {background: rgb(109,70,118); color: #fff;}

ul li ul {
  padding: 0;
  position: absolute;
  top: 48px;
  left: 0;
  width: 150px;
  -webkit-box-shadow: none;
  -moz-box-shadow: none;
  box-shadow: none;
  display: none;
  opacity: 0;
  visibility: hidden;
  -webkit-transiton: opacity 0.2s;
  -moz-transition: opacity 0.2s;
  -ms-transition: opacity 0.2s;
  -o-transition: opacity 0.2s;
  -transition: opacity 0.2s;
}
ul li ul li { 
  background: #555; 
  display: block; 
  color: #fff;
  text-shadow: 0 -1px 0 #000;
}
ul li ul li:hover { background: #666; }
ul li:hover ul {
  display: block;
  opacity: 1;
  visibility: visible;
}
.box {
    width:575px;
    margin-left: auto;
    margin-right: auto;
	padding: 21px;
	background-color: #FFFFFF;
}
img.middle {   display: block;   margin-left: auto;   margin-right: auto; }
</style></head>
	<body><a name="Top"></a>
		<a href="http://betterwayelectronics.com/"><img src="http://i.imgur.com/ymeg1tx.png" class="middle"></a>
	<br><br>
	<table class="box">
    <tr>
        <td>
	</div>

	<ul>
	<li>Home
	  <ul>
      <li></div><a href="http://betterwayelectronics.com/">Betterway Electronics</a></li>
      <li></div><a href="http://ps3devwiki.com/">PS3 Dev Wiki</a></li>
     </ul>
	</li>
	
  <li>First Region
      <ul>
      <li></div><a href="#frgeneric">Generic</a></li>
      <li></div><a href="#frperconsole">Per Console</a></li>
      <li></div><a href="#frperfirmware">Per Firmware</a></li>
     </ul>
	</li>
	
  <li>Second Region
    <ul>
      <li></div><a href="#srgeneric">Generic</a></li>
    </ul>
	
  </li>
  <li>Lv0
      <ul>
      <li></div><a href="#lv0perconsole">Per Console</a></li>
    </ul>
	
  <li>Other
      <ul>
  <li></div><a href="#other">Other</a></li>
  </ul>
  
  <li>Contact
        <ul>
      <li></div><a href="mailto:bwe@betterwayelectronics.com">BwE</a></li>
      <li></div><a href="irc://irc.efnet.org/ps3downgrade">#ps3downgrade</a></li>
     </ul>
	</li>
</ul></body>
<br><br>};



print F "<b>Filename:</b> $file<br><br>";
print F "<b>MD5:</b> $md5sum<br>";
print F "<b>File Size:</b> $size<br>";
print F "<b>Validator Version:</b> $version<br>";
print F "<br>=======================================================================<br>";

############################################################################################################################################
print "\n\nCalculating Statistics...\n\n"; 

open(my $calc, "<", $file) or die $!; binmode $calc;

my $bytes= -s $calc; my %histo; my $buffer; my $filesize= -s $calc;

while () {
    my $buffer;
    my $result = read($calc, $buffer, 100);
    if (0 == $result) { 
        last;
    } elsif (not defined $result) {
        warn("Error reading from $calc: $!<br>");
        last;
    }
    eval: $histo{$_}++ for split //, $buffer;
}

my $calc00 = $histo{"\x00"} / 16777216 * 100; $calc00 = sprintf("%.2f", $calc00); 
my $calcFF = $histo{"\xFF"} / 16777216 * 100; $calcFF = sprintf("%.2f", $calcFF); 
my $calcOther = $histo{"*"} / 16777216 * 100; $calcOther = sprintf("%.2f", $calcOther); 

close ($calc);


############################################################################################################################################

my %ros_md5_list = reverse qw(
4.41 A99F5D9E9C631CAEA6D805EDC73DF541
4.40_PATCHED 7B75FF7995C4B7841B638B27BE3674C6
4.40 AEF60D87485B4D4B49766125290E020E
4.31 5888F186C7B1B5198F221806201CE7AC
4.30 C7398C79576A90888DE0887DB9B5FA46
4.25_DEX 274BB74ABFB47DE9E9E05BBA154E4D5D
4.25 FFC76060A2A48FBE91E577064A343878
4.23_SEX 5F47FDEFAD2949D534A55A6D9BB5661B
4.21 9A01E6AC0F70D4AE33ACAE0C6B17C66B
4.20 6ABEC8C997E6CBDB6B07A31CEBB15128
4.11 F57AF374CC32D73068C98BD9FF0886D9
4.10 87C511E4FC9E51FE6B424A09A409DFEC
4.01 E9792C462CFCD5C0C527A8ED77F6FAF7
4.00 7772192FC02919457D97537DD41900B8
3.73 A0827D76F362D303A25A3103156F5B70
3.72 9E8D2C63D432B1A1E53FD05AB8E5262A
3.70 010CF52C1947997D2C44473726116305
3.66_DEX B5ADBFD3D80F059BD4B83A0CC300F568
3.66 974CDEA2E646758EF40D659957F6E93B
3.65 8005B653D1A28FC9592145DC33DFA64F
3.61 4DA682B0A4408475D789B9C49AFEE737
3.60_DEX C80CCC2D6CCEE7A200E5E3C6A4DA9A7E
3.60 FA0AC8FFDCC06A8C39179017F150BA88
3.56_2 128CC2CDC5986C3C9F4DD56E74DEF184
3.56_1 4474E75E93D66E15377339F96A5D13F2
3.56_PATCHED 6CE56CC2BD4238E831E9A64E4547A81B
3.55_PATCH FCEAC0A025F8225E523FA190B38B540C
3.55_PATCHED F162E0D72EBA0F46B7FB36E6AAB63958
3.55_DEX 102E229DF047C1693ABFBFF5707BE84C
3.55 A974F88457424AC6D8E262DBF3ED7AA0
3.50_DEX 38BBDF08BA848FD1AD170B37A7BFD143
3.50 54AA1F0FF3F10F9806544C8E38E5ED3F
3.42 4E9BDDA7EF6E34B1FA433DD016F6CA2A
3.41_DEX AFE1199881B1C015DF29092C49EFEEFA
3.41_2 C2FE27A86B3174685B5BB15917F27381
3.40 99A69A693A3E268D188623DE4C937CFC
3.30 2DA64B79AC538E7AF643A7E0F0FA64D0
3.21 2DC52F5E40F1B9560C760752477599AB
3.15_DEX D1E4A20987FE6FDD0BA446197005CBD7
3.15 38B9881CD317734B345E10C1FBBD8D45
3.10 46B80BF64C20157AD4B0CD6FFB536CB2
3.01 47D078F5F298743B435002A7C0FEED8A
3.00 B988CB3582838CC18F8B7D150074248E
2.80 BE82801857BADA8FFA9A353F10E23CDB
2.76 1F53B042118AE44B9C7939D887882785
2.70 094A2E6772B8548019BFADA384828E5A
2.60 93DDE807275889858514B72C8C52E3FD
2.53 968B4AB41D973D83BB34F4586EAAA3EE
2.52 85ED932A7ED992A8609B691EB20C8A4A
2.50 0F214D76731708447829ACCC5756D4A6
2.43_LEAKED_JIG 4C503EC4737A08F79FD8B4A4DFE0F31F
2.43 0647A46118311E2D20E7D09205B9D5EB
2.42 DB010865DB5E2D73782173D992C9B3EB
2.41 41852D3A1EB5DD8DF253926A61162AF5
2.40 08F7264FF08018BA346EBFCC96A2398D
2.36 773E896E3F0ED2E8FA30E000BC39A2DC
2.35 8E90D6483CCB71AA78780AAF43CC42F8
2.30 580E9F9C41CB2D4FE02687FD043C0B0E
2.20 249C426A359C30C93ECBB65B58C27FBA
2.17 FD2166CB121C8A4382B9872C5F06BB8B
2.10 9E03564621E6428276FD8D48AC2D15E9
2.01 FC81DF6DEAF57F8866C1B317821C0BD6
2.00 A0E7CE5FB1EF51BED74C0F0A0F682EA8
1.93 6162C9872A5126876054F306968F8451
1.92 FF600639D3A4D33B5040D14C3AABFD08
1.90 6CD39C1EB20D8B490931C19932F43966
1.82 33244E28A563D43B841DCCDA3D60B13F
1.81 88D2FAF7EDE04E5BA0CAEF8635BDEF58
1.80 4FE54D3DC7F455A4E8644831C36D6FF1
1.70 F08F35028CB26728BFCE879AF8360549
1.60 9195FDDBA5EB8E5497EBF66BB21E92FD
1.54 15DF1230C9B399D8BD09194B2C6B02E9
1.51 3022F1A15DA9669DA2FAC7B9727B2694
1.50 5CD5B52F46B156A73EA2BEE9235D99D1
1.32 41CEF7D4DAEEDEE28BDED8EC9D045098
1.31 763A0DE3F5AB7E63DFD899691E234621
1.30 EED51CF6C6E86496FA779C100BA11BA4
1.11 ED918905097A954C3827B991B1CC527E
1.10 371375E22B6EB5DFC75BE864D4493978
1.02 77DB1082B0C808D28A36C96A7468F5E5
);

my %TRVK_PRG = reverse qw( 
UNKNOWN/4.xx 8F220B52C96775E2E80229B186C2ADD9
UNKNOWN/3.50 727554A737024D7C5222B86FE6AFE614
UNKNOWN/3.50 3D29E92B10030900E2DB8968956611E8
UNKNOWN/3.60 89449A27BC1DA3220BB8EEB876E2EFB5
UNKNOWN/4.31 ED7BF3C4C44305DB293E931A8270F0B5
UNKNOWN 1AEC9911A867D4525A1A9BC2D9BE7C31
UNKNOWN DA4E79A12F99AD829F9926FB5A5D9942
4.40 E77B26F129010C77F7A6D0D1FFB906D7
4.30 AAB0B5E0E206AA9B919E9B84DFA283EC
4.20 BF728DE7E44B7308DFD81F6B507DF253 
4.31 7B84CFFB3DB4DB6C4F2ED264C5C413B0
4.30 38F41739F715A890598F3523FB56130C
4.25_DEX 7543C580101650016F52D921BB3D9C4E
4.23 5F47FDEFAD2949D534A55A6D9BB5661B
4.25 7251547BB7C1F60F211FF991BF88083F
4.21 D27D88B0FA283458896439924C1364D1
4.20 06B819050E072F00E1CFBADA14D11042
4.10/4.11 1D364CE8487B2398A9E895C5C87748D9
4.00 A30722F12FA0872D87A156F85424013E
3.73 7342AFF50A0CE981DFFB07ABA742CC38
3.72 D2BE1629D2EB07F540A6735824B73537
3.70 59FBBD39CC17406E34F19C09F3DD9D64
3.66/3.66_DEX AEEEF0B234E004DA7B9F10B80D51C137
3.65 E6C2B57E1BC810A9473448971775AF78
3.61 969702263EF47B8CAA3745FE1BF9B22D
3.60/3.60_DEX 38F60E2302C0ABEB88EF8058FBF45480
3.56_2 3369B79830062846EAD00BA82546C06C
3.56_1 B89DB85F620A44535B874744F5823CE1
3.56_PATCHED C04938D7DAA116120DB3860A94740205
3.55/3.55_DEX 9A3060D30A25DCE7686AA415A1857319
3.50_DEX D7B99A10B7968C2E9710ABAE2CC765DD
3.50 C67C0E8750BE22D781C5168FE631145F
3.42 15C630F1EF0F70F968829783F34BBB4F
3.41_2/3.41_DEX B9FA9B2128677D0A0147BB1779A846AC
3.40 7B558127CCA04DC3031453AEAEA36066
3.30 E4B49673D8DFCFB8D1004D65F25E9A95
3.21 006CF0D4FA748A746B0FB2EF8B9F4462
3.15/3.15_DEX B3D7874BF265BEA925531D4B6FD84575
3.10 D80CBA5A722EA10BD1EE452BBB9DE7C6
3.01 05029C4F31921A5B1E5199F586AC0099
3.00 EED1F52FEE408C5E9AAFA6797DC6C1EA
2.80 7C25D70ADE0FD709D182A9E07445E4EB
2.76 9E0C34B1C6DFCF85E86C254249F222FA
2.70 3534B73AD8417A35D5DC8B371B45A171
2.60 A34DB715070E75B3F7A76B48D7F3939D
2.53 EEBBAE430CE7A723C1769F77914FFC75
2.52 63E0721BD4C712738B8CFDEFE7A16D6D
2.50 AE6BD7BCAE934DF1D4A0364E8FFD8D2C
2.43 784C73FCA1FB0BBB9162585586701895
2.42 E73F305D7386AD65ECA1737DDB20C212
2.41 AF62192A127780A7F3FF74F497F2166B
2.40 592085BF608BA98CDCD97F83D0585D8B
2.36 30AEEDE2A064039CA6523CB81897ABB9
2.35 53FDFB27E75A071DA477E4E23BF5D95D
2.30 1DA4956E0716A221770700910B326DB6
2.20 6EC24DA67B34757552536F5A64031DE3
2.17 EBBEA9B7483468A5651E85508E6F9DDE
2.10 E5C8EF3D07917BC13C7E25BFB3181E22
2.01 0EF35CA6AE3B364CD43FBA5F7832B8D1
2.00 FC8C4389D17004220F2EB30909608066
1.93 0928C14E96D725C2FB161A42A3F44428
1.92 F06A8BBFBA08A4C648C8DA67DB4A4B36
1.90 9362B499D8FC74972E2C0CB401E85526
1.82 2C16DDCF3F130295DA202E6DDCC2A224
1.81 FAD825B3EEF1BDD213C74B58E8D695B8
1.80 C22F1C41342904C33A93B2BCC7A9514B
1.70 A039F8EBDC1993860EEA11B126377EAF
1.60 CAAC5DE89DAA2D79DB60F5972F2D7805
1.54 CB006FCF62FA064254E877F2BDEB463D
1.51 2643A3185DEFACC75F5C410BFDBFBA26
1.50 905694B5FFA1F0E49E4860E581B5653E
1.32 E86E439B43E079DBC6759638A9B84891
1.31 88D6850F99F3BA51FA6BB37FABC1A800
1.30 0DB00E61FA8134640800F2EFBCE6F8F9
1.11 410451085E6305BABE8D94FFF89F6C5C
1.10 FC0D846FD88982FB81564D7475590716
1.02 60A4B20FB5B6E09E700E799244C1BC46
);

my %TRVK_PKG = reverse qw(
UNKNOWN/4.xx 01A026B6AAD992BB7FC5548193948DC3
UNKNOWN/4.xx 91584CDE005CDBCBD06C1BFEA1790188
UNKNOWN/4.xx A43D54210B7DC02DC650880FF9AE6688
UNKNOWN/2.xx 15DDBC97AC2E8AE7EE019782FF017240
UNKNOWN/2.xx 5E5169D5A1CA9AA78C2B5C1041132F88
UNKNOWN/3.50 9E8E3D2941E450BC3EF31DC70118063D
UNKNOWN/3.66 E056B25601DE15B90EFCF56CF9B3339F
UNKNOWN/4.31 4D5EA9135953FCA17B8FA8D28E9DD740
UNKNOWN 76A2B8344262EB0AC708B5DA2434C38F
UNKNOWN 02F2E228A865E55DECEA5CAC8EEC88DB
UNKNOWN 24E4955B023CEA8BC6FEF9D310300F66
UNKNOWN 891E968BDF18E3667037FA0D54C3A9F8
UNKNOWN 1B3A78E7324C2A67AB8C219A5CFDA631
3.55/3.55_DEX DD4AEE95E33F19F4A183886B6AD0ADDF
UNKNOWN 1EFAC1E0C28112353D188A00EC92718B
UNKNOWN 87827A3336F862F0E7253EC45DDCE989
UNKNOWN DAF2DCCA0752762E58E059F90D73F825
UNKNOWN B009C56D8AB60CC8BAF91ED0364A0E98
UNKNOWN B0EFEF24F3743F2FAA5D2935CAF1661D
UNKNOWN 4B1ADFF1B137EB2BCE88D3DC48881043
UNKNOWN/3.60 C62BCD20484A6F61280970F3D9DD8935
UNKNOWN 60C3DC9D3E809ED834C0039E4BF81D24
UNKNOWN A257F8CCA77A6CB4E219488E86BCE794
UNKNOWN 38F02B606B50E9AC3401C23620B619C6
UNKNOWN 6871BFBCBBE458D06DCC71746A0A4C77
UNKNOWN 9851B18D618BFF93C5FC07743FE8CE09
UNKNOWN 10E066280194FA824A0665F02BFAB2F3
4.30 D9045762F487268D346E11DCC29BF697
4.25_DEX 6AB35C1F02B584AE84474D7ABECD6BDA
4.20/4.21/4.25/4.30/4.31 CCB14FE47C09CF4585127CFF2CE72693
4.10/4.11 B73491D0783489FEE31847261364ED41
4.00 BCBBD3B8F0D6F50AE45B06EC53E1DF3F
3.70/3.72/3.73 3947F77FD2E2F997E1E03823C446FB60
3.66/3.66_DEX DE8E6C172782047479638C1EFEAF0F51
3.65 EA38E7F4598F5A20F3D5CBA0114AC727
3.61 16ADE352DAEDDA3FA63A202C767B4C7A
3.60/3.60_DEX FF273E1B10617FA053435672844A229D
3.56_2 A38264BAF9A6BDA0E5B1B2E32E2B6A28
3.56_1 E93A19A2DFE59DDA3C299EA3B9A7F045
3.56_PATCHED C260E1D02AA9C70E1CDE53474CFD86F6
3.55_DEX 3F807A034B6DCB21F53929B5D0570541
3.50_DEX 27B27ACD2075A04CF277C0335538157D
3.50/3.55 9C050BB7146E394413804E9E1E9F7FA6
3.41_DEX 89B8674638DD06611C3D6946CC0231AE
3.40/3.41_2/3.42 E080E353F2D9A1548E3014D2DC6B4BBD
3.30 BC3A89D6F7D66B64376C0DFF13D6B867
3.21 7BCF9B229FD7AF99F7AF955243129354
3.15/3.15_DEX 9589EB7F93B5371E0CB60D454C67ADFA
3.10 EC0945F3AEA4A71A2E5E43C5A8ECD594
3.01 A7826026D5403024810EDC1E4DD77A52
3.00 95108E059B65E5C1CE6A4A8089089A60
2.80 32F5E69E8DE7B87DACC84A92E7025559
2.76 CDF88CA39FA271D25C18A2FBE5F9F7BE
2.70 22E2A99BA76E56F0957A7CF9FB145978
2.60 F36B3654D90C1578362A8A1510D0BBDD
2.53 DC0D0B66621C6DFB6704DBF28C58352C
2.52 26401229922C74D4C87D0DF003D235F1
2.50 22EFAB44D5CC3D7BA3AF05A4C283E1DA
2.43_LEAKED_JIG 50AF53AF6D53F84D6D92EA6EFC5671DD
2.43 98BCA0307B2843A815176804947B68E0
2.42 93B7BE6B8302848FA27EBB8C3E01AE4B
2.41 505D3CFFFEA7E6085DB5A92C08BFD9BC
2.40 8DA31A5EDBE973EF0B054E34304F3BC4
2.36 FFD0D46F1B1675DA9A5A9E00AF5D71DD
2.35 B6E9AB2CCE06F244FE6BFED3C8244082
2.30 95CF8B4D7C88396AD71B2837909DD847
2.20 02DB8CA8361CEC854DFB339644A5D997
2.17 EC9DD3B077A4F42B42AF20A82E07A1EB
2.10 EBDB8D9CF82DC1F53ED1EAAC39851F6F
2.01 18B410877F6F962E92B7AECD91B1CF0C
2.00 4FCEFA3CFB8D731E90B53FC949151C91
1.93 36AD871B0BB839C02CB4BDDBE52FEFEA
1.92 B594EA4DB3B3A3D1FB02E0B2B6EE2201
1.90 A11A6F728B0086E9082BAD0506C58B94
1.82 653434FF27E82FAA04FFA038784A1E7B
1.81 C03376C49B7D028094C340E7369CE912
1.80 A17466375FC6B6E2E8D8B0F223012F85
1.70 3FAB9C9B2C13DAD1D634493F04C60609
1.60 29B657AB7327CD1F00B701AE6B7BC179
1.54 5D2516B29A9C2E56C3E1C5F2F5883FF0
1.51 39BB79DED88187372F06B2F5D393D777
1.50 847F9F54A392BCC3F059F2352F4E844C
1.32 D08A3FD2C5B8468C4980BCA014EAA47A
1.31 C01D8294B4F319DF0CD1CA6CC4480826
1.30 7111A00520ACE60D17BB23709F5EC4EC
1.11 6D49077177812D9D6FCD289FD1EDED90
1.10 EA03F7AC248C5B5228D8B40B13A27AE8
1.02 B7829DD4B09C25B6918BA78BDEACF07F
);

my %ros_md5_file = (
'09A1D434DBD7197E7C3AF8A7C28CA38B' => 'Unsorted',
'1ACE0B566F3C918435395224A8D41800' => 'Unsorted',
'334864960650010F259CF024DC74C9F7' => 'Unsorted',
'2702AAF5E12091500FC465CEF6792EDE' => 'Unsorted',
'DB777CC78D0126A1AC9831486602EB70' => 'Unsorted',
'6943FCE42237242D02DE8E61B25C8EF3' => 'Unsorted',
'DEEE53CE82F44DE654D969EB5A15E4CC' => 'Unsorted',
'06CAD08136CE161A9ECBA703369FEDDF' => 'Unsorted',
'95537BC1D7D1A900F81017E3AA9681EA' => 'Unsorted',
'6F9669CBA2824C0F4E6620E1D364006B' => 'Unsorted',
'ECF2AEFC1E8C1BCF8C633F555A563A4C' => 'Unsorted',
'520CA3362C1652625B2548E6A1D199B2' => 'Unsorted',
'B5E9C2902C60AD7EC77F2BE742337817' => 'Unsorted',
'C1458DE986F16D8ADC8E19DED77C9B75' => 'Unsorted',
'3253B21C4D23DF9B8F56B7B90349FFA5' => 'Unsorted',
'897FB25B07925D74DF94F97FECEF8660' => 'Unsorted',
'321C2767380A53A076B730A50D980CD8' => 'Unsorted',
'40327817B9C0172B5F27EE761F0D24A3' => 'Unsorted',
'82F6981183DDE3431CCF666307E89DDF' => 'Unsorted',
'B5F54D9A11D1EAE71F35B5907C6B9D3A' => 'Unsorted',
'F5E81EA05E2C5888FE76A00D5F28E5B5' => 'Unsorted',
'FC4EB8E2C55EEBFB6450A1D398DA492A' => 'Unsorted',
'09A1D434DBD7197E7C3AF8A7C28CA38B' => 'Unsorted',
'B5A1515C522387381AB6421AD254A4F8' => 'Unsorted',
'43900774135C9717FB487169CC9AB9FA' => 'Unsorted',
'7A1C819E4825EE2E15A88EEF8D289E38' => 'Unsorted',
'1E610D1AFB6997D1C16BFCA319CD54F3' => 'Unsorted',
'227153439D94A41A06ECCF85EDA7C2D1' => 'Unsorted',
'9F97D6EB1A535EF1FC3076EB5552F0F5' => 'Unsorted',
'FE0F0BA169F16D9836691620348DD652' => 'Unsorted',
'EC9F620C942A94DC848980CBED6AE7DA' => 'Unsorted',
'55D7060941E20F53290AEC8CA8E5F7AC' => 'Unsorted',
'E8A71707FF9CDA8C6AECD058692400EF' => 'Unsorted',
'9BCE2FA3EBA883D88F247DC61D708A08' => 'Unsorted',
'78155D58BE26352E2C22FFFA931914EC' => 'Unsorted',
'F08A2848000121746029916622453E09' => 'Unsorted',
'9780FA593C0235136A2B702E1CFBFC9F' => 'Unsorted',
'4DAB8A4AD9D0E51421DF5E418E30FB9C' => 'Unsorted',
'C22F4566E91BCC8F1A3F32A033E270FD' => 'Unsorted',
'085B6920EDB4E9018669983803F547F5' => 'Unsorted',
'7D05A2AF4C36BB28DC7D2CF3D51F78FA' => 'Unsorted',
'4DDF8424ED7605AEC14219EDC8E0B76A' => 'Unsorted',
'B5F54D9A11D1EAE71F35B5907C6B9D3A' => 'Unsorted',
'AB19755BCFA7B7AC97124645F60F7D41' => 'Unsorted',
'09A1D434DBD7197E7C3AF8A7C28CA38B' => 'Unsorted',
'4300DBF2126DA098A20FB52C1DBACC07' => 'Unsorted',
'6BD47021288ECE0671D2ED1599628FD4' => 'Unsorted',
'ED8C7175EE15BB331C2E1672A781B489' => 'Unsorted',
'2C570EB1242567AAA801B06289A6FC72' => 'Unsorted',
'309C7E5EFFA7EA281C8BF48714A4C2C9' => 'Unsorted',
'1202CE9B31CA646446ADACD7ECB5A428' => 'Unsorted',
'C17DC23607826053044F6689B0DE62C3' => 'Unsorted',
'FE2A1C337E0BCB471317574BFDC482CB' => 'Unsorted',
'8D3C4091D7EE491BA3DF7C1478EC98CE' => 'Unsorted',
'77E398F06E9FD06DED31611CF0F4EED8' => 'Unsorted',
'CFE3149850C005CE461DDCD70795D23E' => 'Unsorted',
'3AA425CDB200CD6338668231581A1678' => 'Unsorted',
'C63D635ACD1E1C4CF7F647425596EF5E' => 'Unsorted',
'F234B5BBAD6DAA41B45EA154CF56C74D' => 'Unsorted',
'8B11E7CCA40C9773262842EE73708A7C' => 'Unsorted',
'C5CBEBD2765AD8DEDCBCB662CCD6814D' => 'Unsorted',
'B2D37BE9BAACBED6151BA4AA93ED982C' => 'Unsorted',
'6AB0CC65FEE4458D35AAC66CAC20E931' => 'Unsorted',
'CEAD91A9541EEC4AE2A5CF25AF23CD30' => 'Unsorted',
'B5F54D9A11D1EAE71F35B5907C6B9D3A' => 'Unsorted',
'41B6A074B58A50123F10E8CEA92E90A1' => 'Unsorted',
'47D078F5F298743B435002A7C0FEED8A' => 'Unsorted',
'09A1D434DBD7197E7C3AF8A7C28CA38B' => 'Unsorted',
'E6B9E569A71DE2DEF26EE427DF2E4714' => 'Unsorted',
'E769E2544B6138EB9ADF842A5C3CFA3D' => 'Unsorted',
'18F904797EBD94EEBED39B89E0DE20A6' => 'Unsorted',
'D0AE02BCFA38AE11588405DC667A0E5C' => 'Unsorted',
'F57AA8062B6C2C4FACE441AC9D3C10D3' => 'Unsorted',
'B4C103D1D45FF8F6C4C0C4B693D66C2C' => 'Unsorted',
'C57DA3C86590FCBB79CFE2248415CD31' => 'Unsorted',
'E956D4FF9F3F10B03214E5C640B91640' => 'Unsorted',
'ECB95F782CCD0C55D9D470043A14AA0A' => 'Unsorted',
'7600B684BC2613064E4E59476AA40DF3' => 'Unsorted',
'817C4BBE4F13294F6D524C4A29A470C3' => 'Unsorted',
'8837F1FF8F442F67F2F301934D78EEFB' => 'Unsorted',
'BF3FE1F9E5E9DF3F5D77FA69DF2E9227' => 'Unsorted',
'1498C8ACA2AD760811C110C54C16F95D' => 'Unsorted',
'FE6F00FF8CF2EF50EB8BE63B24FCCC14' => 'Unsorted',
'4E728F293292BC8C6D94D73441C8D175' => 'Unsorted',
'3450FA1103883FF9B2961894B30B7AAD' => 'Unsorted',
'47A3FEB993057B6E97CCA48B2FE5AF4C' => 'Unsorted',
'17C1DE9EF35AA6A7C3BD823456AE11DC' => 'Unsorted',
'B5F54D9A11D1EAE71F35B5907C6B9D3A' => 'Unsorted',
'F217AE7290831829B0BA3660A7EEB8CB' => 'Unsorted',
'09A1D434DBD7197E7C3AF8A7C28CA38B' => 'Unsorted',
'1192A5ACB51D338552EDFC38EA8DEC19' => 'Unsorted',
'F057A273641EBD3672E58985636346D6' => 'Unsorted',
'DC6E13FE071C52242A22186FABA5C8FE' => 'Unsorted',
'33712A941CC6C98A9DF674C45279CF14' => 'Unsorted',
'6B08621051BD5D6C24B2BF40D03E091B' => 'Unsorted',
'A1D62AEADB139D942CBF381955E21435' => 'Unsorted',
'6E59499B52C07E2D287EAF2C8CCBCE55' => 'Unsorted',
'7E4768B99984A69F873728A6C19AE768' => 'Unsorted',
'6FEF6A006C98859F53109288C39D041B' => 'Unsorted',
'AEE94073EED437062026E219B741B82D' => 'Unsorted',
'085EF8B40FFFD8C6D423AC60A1B0DB17' => 'Unsorted',
'259EAF48D42005361A5C9B03F0442962' => 'Unsorted',
'E807DC2FD2E73694EAE6744A998E10F2' => 'Unsorted',
'D70B75D4689326B9718E65BF8F4B024A' => 'Unsorted',
'4DE01F182129E13061E218CD98A735B9' => 'Unsorted',
'8AD1EE46A40424855BCCA486C39F726F' => 'Unsorted',
'823BC869CD1ED8873F5A110A9F7347AF' => 'Unsorted',
'DA4649DB98B6B2BC0DF7B07E91171A0E' => 'Unsorted',
'33FCB1C3F10B7582A79F0C300961DD17' => 'Unsorted',
'B5F54D9A11D1EAE71F35B5907C6B9D3A' => 'Unsorted',
'1E6A9FEA2B5D79C235A254AD6730BE81' => 'Unsorted',
'09A1D434DBD7197E7C3AF8A7C28CA38B' => 'Unsorted',
'9A5BAFBDA4C414E884A8B4F5F58E002C' => 'Unsorted',
'CE5269534CB094D83C9CB6A9E199E4A3' => 'Unsorted',
'592BB9EB64FC767EF0E65A3988771C3A' => 'Unsorted',
'4A5253F71CA5A5C8CCFD8F990663BB74' => 'Unsorted',
'13BBEA44F0EB32DEDB7291DF2B441A75' => 'Unsorted',
'D0F6BCA5055C0B839CD82D893B57F823' => 'Unsorted',
'18D2B38B032E4C6CD83AD207BC713384' => 'Unsorted',
'2E687F9D304AA82ED22BEB558876F719' => 'Unsorted',
'A16463EBCF1A78A7CFCCADFFA71A6C84' => 'Unsorted',
'168B6961664DDCBF9ADA4A383EE012B0' => 'Unsorted',
'4F9020B1FA7A32CE5945817F435A993B' => 'Unsorted',
'A41C00732C8F51389F080438806C69CD' => 'Unsorted',
'EBE216188215DDCC491B65C51AAD817F' => 'Unsorted',
'C1D7E167B5F702C492091A104613F3CC' => 'Unsorted',
'EE362071EA547D1D1486C4035514F3ED' => 'Unsorted',
'B4809F998BA62B2A299A2769DBDB80F7' => 'Unsorted',
'828B5AA6D8C151A21F08AF59148F59D3' => 'Unsorted',
'DF7D71CFC9B04F6EE62DFBEDF30F0311' => 'Unsorted',
'C2BBC899ADBF70E4273568F81DF40086' => 'Unsorted',
'1DBE0FFFDE95D148ADF85009B2473A7D' => 'Unsorted',
'15FC7A804B08B9B138FC164AE7750BD6' => 'Unsorted',
'09A1D434DBD7197E7C3AF8A7C28CA38B' => 'Unsorted',
'49B118B0B3FC5CC24FE023C97CF10866' => 'Unsorted',
'4FFEF30B32C5512EF6B0EE3B45CFD1D1' => 'Unsorted',
'B239703AA92237A1A9B9F3125F16A3AB' => 'Unsorted',
'C7BC0D6AE641F7B6D6300FDFC1EB1393' => 'Unsorted',
'3C5538E18B97BEF13272E079A84623AD' => 'Unsorted',
'F7D46F7B11481B17A316917221D84C13' => 'Unsorted',
'155FC53947F06BE01CF0D605325C6277' => 'Unsorted',
'F6E3779C1EB47FE102D6E6EA60BEFC6C' => 'Unsorted',
'D8845D654402EFD174522706C543C0ED' => 'Unsorted',
'76EFCF416306107628943A1321433CC3' => 'Unsorted',
'86C1915F89B37A573357E37AFB52D267' => 'Unsorted',
'1A49E87218073360124E16CB81454886' => 'Unsorted',
'B6DAAEE2216EE04C2653ABAA66992ECF' => 'Unsorted',
'9AA211E4DC750B89FB716D4ABBBF50E5' => 'Unsorted',
'E9C37F16C3769A4AA86B31E1A3526CCE' => 'Unsorted',
'B005EB45A84496EC20A4635FAEA388FA' => 'Unsorted',
'B24338EBAB0B2B0B6F4BEDA081D19F9F' => 'Unsorted',
'C9714794306C9F638E64E2A780DC7093' => 'Unsorted',
'4100A573C3A06A9438EA73E2642B8A60' => 'Unsorted',
'1DBE0FFFDE95D148ADF85009B2473A7D' => 'Unsorted',
'4257738AFEF571FB714A0816DB798B19' => 'Unsorted',
'09A1D434DBD7197E7C3AF8A7C28CA38B' => 'Unsorted',
'1EC51F112B3240A46CF3D18F180CE83B' => 'Unsorted',
'9B9F81671707CA79C58523DB793FD328' => 'Unsorted',
'89467FD241FC253810DC3B8C67BA5233' => 'Unsorted',
'6C7F7F771FA7144E6510605A10698744' => 'Unsorted',
'D969A9C2EB414003685F3A845FAF17BF' => 'Unsorted',
'DE3FB1CA9257A74D632FC539E9BE49B7' => 'Unsorted',
'FA0674233C2DF1EAC8F8C8D774DE6983' => 'Unsorted',
'7272CF8734CA585F3F34ED2E53CA661C' => 'Unsorted',
'B1E3D58B9CEA82F8DD8A38AD9B9B3BC8' => 'Unsorted',
'853498D9C790C45403800DD00AADAFC3' => 'Unsorted',
'92B59E70AA3E17412D6D4AF3B2651802' => 'Unsorted',
'F6B2C0663B307CC8B67B1B1429F2B925' => 'Unsorted',
'0B5A8A1AC0DC5D07746F022819CBEFD1' => 'Unsorted',
'C21C6125EA59095F921986755DA244B7' => 'Unsorted',
'6F663443B3D0F3B9B716DE80AD80E1FB' => 'Unsorted',
'9DEDA6A83580B4331641D48DF611B287' => 'Unsorted',
'401DCDE5B8517221392582EB8D5636A6' => 'Unsorted',
'711A7BAA1D4416C1C23B8106E1C995FD' => 'Unsorted',
'D2670CF1BCE4CAC107E1817EABBEEAA7' => 'Unsorted',
'1DBE0FFFDE95D148ADF85009B2473A7D' => 'Unsorted',
'BDB3C79D5BF2D230AEF4E02D708ACA29' => 'Unsorted',
'5660738584765ED469AFCB9FF9A9CBE0' => 'Unsorted',
'2CEC67A17DD9B52CD939C9C232A80FAC' => 'Unsorted',
'8BDE5529D6E4B1E94D7DC51C498C5528' => 'Unsorted',
'49EE926FB22EADF33A64ACF8A41635BF' => 'Unsorted',
'643EF91ADEA21A31A10068544FAA760E' => 'Unsorted',
'09A1D434DBD7197E7C3AF8A7C28CA38B' => 'Unsorted',
'F4083BBBF5FFE3233726BD13FF9E7198' => 'Unsorted',
'466CBA313C4985FF15CC5D902F8F465A' => 'Unsorted',
'6EE7D38EFF03C4A44C7A803C43E41B7C' => 'Unsorted',
'79F2FB2C70225FF1FEEA613D3B5E7774' => 'Unsorted',
'74F66BAC1CC9DB0021F34042573472A9' => 'Unsorted',
'30473AC11BD9E9B1A34C8A2CE6544992' => 'Unsorted',
'2107F5E6BC92E68AF0ED0619C86E3A6A' => 'Unsorted',
'FD7E7C417D347D9FC1B695C011BDE609' => 'Unsorted',
'79292E54D16278B09B46BF00CF34E0C1' => 'Unsorted',
'B73638E3081772E4F9B0B119BFC3E6E9' => 'Unsorted',
'C1780ED58633BC26A27D8BFB5D56AC2A' => 'Unsorted',
'050D92B5DA1436BFC3644DFFB3C2E764' => 'Unsorted',
'7341CFFB4AD5AB2D966E8817CDF11D0D' => 'Unsorted',
'EB0E074866B0871C64EEF7FAAFFB15B6' => 'Unsorted',
'EA22717349FF3ECF6224BE6FA3C8380D' => 'Unsorted',
'4D16421774AA9CB931AAD0513A4FFA4C' => 'Unsorted',
'C0A80D82736F0FC464620C2930646915' => 'Unsorted',
'C1AD64905311AD7F1D52BE33EAA28A1E' => 'Unsorted',
'B5F54D9A11D1EAE71F35B5907C6B9D3A' => 'Unsorted',
'73853AFE2E7BFA47547C143CD22A47EB' => 'Unsorted',
'FD1F037CAADA6F8D7D9DAF275E82DD49' => 'Unsorted',
'74858C62B1645BB1F8C57665FD53F9A1' => 'Unsorted',
'5E0E9E8BAABFEA9DAB798D38F517707C' => 'Unsorted',
'6CAA0F654191150935C6EBCBA5B40518' => 'Unsorted',
'78D6A93580B3ACEC3A404AB37A7F654A' => 'Unsorted',
'36A1C27D6950CDF83A08DD77059DC550' => 'Unsorted',
'294695EA23D3569D34C7F0E0CCAE04A5' => 'Unsorted',
'0B769C15D04452C2F91B6A27EC5C8251' => 'Unsorted',
'A02BC17E8ED634300A31BA783C480382' => 'Unsorted',
'0CAE1D0AF7EEA1D23B95DF40812422CB' => 'Unsorted',
'5B35BB4EF4CE82349BB9BDFA0BED1B09' => 'Unsorted',
'ED41E51637B6EA2B2AAB616182D6A83C' => 'Unsorted',
'E7D1A31F6EB4E6E840700FCFEAC217AA' => 'Unsorted',
'67373DCBE7F6F208B53A2DCC74E5531E' => 'Unsorted',
'1B7D4D3CEB4CE0C586E7AE7FB14325E7' => 'Unsorted',
'897081360F599281B5423143BFED661D' => 'Unsorted',
'60B7BF6BC96163109793DCDED75F88BF' => 'Unsorted',
'65F3583701F36C5C127F57B9E4BC4C48' => 'Unsorted',
'9124888B472E7BAA04824D045B7B6210' => 'Unsorted',
'1FDFCFDAEEB0BB0C0C5A246702ECB6D1' => 'Unsorted',
'A484DE8056F27F8D15BEE45408CD7CBE' => 'Unsorted',
'09A1D434DBD7197E7C3AF8A7C28CA38B' => 'Unsorted',
'9496940BC3CBAB8E06CDB8DA1A8FB0B3' => 'Unsorted',
'70CC06C9C4E2B7DEC397425065020BA4' => 'Unsorted',
'2EF1679656908524F65926932D85B8B3' => 'Unsorted',
'93F715DB4499344E72315290A00014D3' => 'Unsorted',
'F89EBC0F8270D651D3143A4AAB696B4B' => 'Unsorted',
'C5038FBA00845CCE9B9E61ECB15DD7B6' => 'Unsorted',
'1EE8070323E165EA687AAF9FE9002F61' => 'Unsorted',
'A71FCC4F3B33B009A21BF44926348694' => 'Unsorted',
'9EED10FA460DA1731319ADFFAE848455' => 'Unsorted',
'4913B8C9F264BADF81BCD8F53F9257F4' => 'Unsorted',
'D2E97F0C6E2FCDA18F94BC8E9241C90B' => 'Unsorted',
'066D2A3F7ED4670667B6402FF5F1741C' => 'Unsorted',
'5235E2AD69FB63D311717DE441FF7B6E' => 'Unsorted',
'A88C5BA3789CB5FE569D416D24123FF0' => 'Unsorted',
'78E101C6217EDB7E0EAAB48D0EDCE4D2' => 'Unsorted',
'CFB561F7322995A899DFE232773CE215' => 'Unsorted',
'604B42A216E8833936D061AAD16F1E77' => 'Unsorted',
'0A73ABDF1A4525F2C08208368BD0CD3F' => 'Unsorted',
'B5F54D9A11D1EAE71F35B5907C6B9D3A' => 'Unsorted',
'47C5FC6D298FB7404646561D8B887A5C' => 'Unsorted',
'E2C5D2DCFEE8C83C2B7B4BDCDFAC186F' => 'Unsorted',
'B2E08DC15D8C5B836731AE910F63BA19' => 'Unsorted',
'36FC5E86FDE1B59AF91AF0E66CC1542B' => 'Unsorted',
'9E8D2C63D432B1A1E53FD05AB8E5262A' => 'Unsorted',
'E4B49673D8DFCFB8D1004D65F25E9A95' => 'Unsorted',
'05029C4F31921A5B1E5199F586AC0099' => 'Unsorted',
'02DB8CA8361CEC854DFB339644A5D997' => 'Unsorted',
'15DDBC97AC2E8AE7EE019782FF017240' => 'Unsorted',
'CA9BBC99C645173E1F98AA66C47A4500' => 'Unsorted',
'5C7436BFFC7E8D0A8E210BD0CA83CDF2' => 'Unsorted',
'B0AD88EE637311AE5196F1B11D43BE0A' => 'Unsorted',
'9D670B662BE696C8460449B7EFDD803E' => 'Unsorted',
'C1DC055EF0D6082580AC066E2B0A3C38' => 'Unsorted',
'811329ECDB677181B9FC5CC3564D9047' => 'Unsorted',
'FF6753184D15F45508C5330A6144A4D9' => 'Unsorted',
'128499C45F6A66D48FCC0AFAE075C188' => 'Unsorted',
'E9AE2A62B4CC31750D4E56C7D5FFDD6F' => 'Unsorted',
'A597AA3D8101674856EEF83AC1D0EF28' => 'Unsorted',
'BE1F3E74C85FAF93F6BE893D7EC75138' => 'Unsorted',
'65A3EEE4C48716674CB1C29609B5F54D' => 'Unsorted',
'5FFB33A6CECB99081E54A0E36E3C61AF' => 'Unsorted',
'3B15C14770D654FEF9987E2517616D89' => 'Unsorted',
'B39E13FBD6B07F65616A0355EF5CB262' => 'Unsorted',
'D7EDCA0ED3749F11EE34F0F532CF5AA7' => 'Unsorted',
'3DA12E2CB472EB8193309B663D7C913A' => 'Unsorted',
'90D1C8A45F6FEE52219E1B14FF8C9765' => 'Unsorted',
'B76B7244B19032A9518787D9EC827F3C' => 'Unsorted',
'22ABABCFC027F892AD2CF4E1C9FD925C' => 'Unsorted',
'0E5A2E8A68FE09481D728C227DC5A165' => 'Unsorted',
'368F2D290C00F3CB3C5A5C8CFE584534' => 'Unsorted',
'F162E0D72EBA0F46B7FB36E6AAB63958' => 'Unsorted',
'9A3060D30A25DCE7686AA415A1857319' => 'Unsorted',
'DD4AEE95E33F19F4A183886B6AD0ADDF' => 'Unsorted',
'A01B32CD2B1E29FA0351FBE1BC1B986F' => 'Unsorted',
'28F7DBB9DFCC64CBFC31D065A476DAD4' => 'Unsorted',
'AE8E4A8F29B78D62E3FA72EB32CCF3E2' => 'Unsorted',
'B9FB697C1FE64B0C3323AF0B860331F3' => 'Unsorted',
'71BE4C9D062AD3FE682F51467788F39B' => 'Unsorted',
'E3D1C5125F080490955C938511855482' => 'Unsorted',
'678E330A794A04952C553810BE4A824D' => 'Unsorted',
'E2BD05A2EA6D0FE4BA8AFC77F508AF75' => 'Unsorted',
'D4458D316C7F77F426EA98A560FEB689' => 'Unsorted',
'9A34120704C08358E6ECAC560F4EA7B1' => 'Unsorted',
'94B668D9964D39F0FFFFA2532E9290D3' => 'Unsorted',
'5F3705A9A4B9CD0D33303623DFD02220' => 'Unsorted',
'23BE2713AB61CCD9FE946F2894BE3D02' => 'Unsorted',
'88C5C6FA11BD34C2155F58FAF5B84A89' => 'Unsorted',
'09F6DACA862850E57906F305A320F95D' => 'Unsorted',
'2FD2CF54908AEE6884AAC2EAB4CFDA86' => 'Unsorted',
'2E665676F2E9B1D95C5C745E7D7A5339' => 'Unsorted',
'0AF3FB68187C9599C1DA7DCADC903601' => 'Unsorted',
'62073B10B22126FA539E4AEA2BD34816' => 'Unsorted',
'168612C5A0FEA5517C04BB244C4074C9' => 'Unsorted',
'4E05177E68B51CD50E868ABFFC336269' => 'Unsorted',
'1085132297E8FA266AEAE703A15858ED' => 'Unsorted',
'6061903C18588CC21378E51EEB2486E3' => 'Unsorted',
'B37640A823BF99A3D8ED8648ED794775' => 'Unsorted',
'FB24D926795BD6699F4BE223503584C8' => 'Unsorted',
'C9941767FB71452CC0938176551D093B' => 'Unsorted',
'10B2B7605A12FC6B3484610A4C69B088' => 'Unsorted',
'E636C4B8C3D651E1EB6DA12AEA36719B' => 'Unsorted',
'46583EB70BF1D74BA9814B509909578C' => 'Unsorted',
'347291873B2ABB08BEFF50029E168A62' => 'Unsorted',
'BB3D836ABF3326ECFEF4AC3A508995EB' => 'Unsorted',
'ED014C7FD47946CB41ACE5687E4D4E63' => 'Unsorted',
'A8D6110CBBBE9B5818A1CA1A29D3E4D2' => 'Unsorted',
'64BB4664DE4FEDB65F2CD1A1D4110372' => 'Unsorted',
'B5461EABCA41F893D172F86A3207BC26' => 'Unsorted',
'F309CA445EDE1618A3CEA90212EE9556' => 'Unsorted',
'E6C23FF9FC968339588B3EF92458D9A5' => 'Unsorted',
'169DECC996EFA6E43444FEFCC9A14741' => 'Unsorted',
'59FD7F5325C91EEC8BB48FDB1CEA769F' => 'Unsorted',
'31B94D71ACF15A6BDB5859D20E2E1CAD' => 'Unsorted',
'6516D84D687B937A11903819DB0FE20F' => 'Unsorted',
'79AAD3B730273C13B576AF900745A9CB' => 'Unsorted',
'FFC76060A2A48FBE91E577064A343878' => 'Unsorted',
'6ABEC8C997E6CBDB6B07A31CEBB15128' => 'Unsorted',
'C67C0E8750BE22D781C5168FE631145F' => 'Unsorted',
'24E4955B023CEA8BC6FEF9D310300F66' => 'Unsorted',
'003F841C96784125F0D3388FAC19A6D2' => 'Unsorted',
'9EFD1B5B436325EA56B591FFF74082A0' => 'Unsorted',
'5658FE830DD262D5692FE7F3DC3D723A' => 'Unsorted',
'797B68E5694EB2072CC944D6F072A961' => 'Unsorted',
'05F02ECA781C7462870E4A80A13E6A76' => 'Unsorted',
'20054C84A4BF7E1237FDAF645101EF74' => 'Unsorted',
'5A6AFCCA39BED9E979B2EADD46D516E1' => 'Unsorted',
'667FC8DB8E5519CACBF8F9F2AF2E0B08' => 'Unsorted',
'FC0D132FAEE4585963887860C33807F1' => 'Unsorted',
'2CB801DBF76FD3C83DFE01D6FF99E824' => 'Unsorted',
'0E6248204D381BE2C21B0630AA7A432D' => 'Unsorted',
'B95D9A045A89DC1CBCA94FD3BB6E91F1' => 'Unsorted',
'13E53D2EC13F91B3C5B0ACFD076C5391' => 'Unsorted',
'C79E5C952D4BF8208668788AB85A019F' => 'Unsorted',
'8073E364721EBEC9AF8082C9A12FF796' => 'Unsorted',
'5CBF8D6FA103C32E8EA94E841D908A13' => 'Unsorted',
'ABA5830829EBD635E664AFC1516D060A' => 'Unsorted',
'21F4C35B7EB584CD3F36AE04E6A4854C' => 'Unsorted',
'6557DF35F9A5446C4340815F45C67CC7' => 'Unsorted',
'DE15FF24BA24A4D00554B8EA874A1882' => 'Unsorted',
'3E9606F2312708E179BC9FABD4824746' => 'Unsorted',
'26B786C982FF62686E0F5D0BEBE4BA85' => 'Unsorted',
'C7398C79576A90888DE0887DB9B5FA46' => 'Unsorted',
'891E968BDF18E3667037FA0D54C3A9F8' => 'Unsorted',
'07D64230462FBA19EE999AA1A3B9E192' => 'Unsorted',
'08E986E8D43A4B1406B38C87842AE99A' => 'Unsorted',
'E005C64998DC504139FC6B6BCB2A60BE' => 'Unsorted',
'A6C8A9D22A85C64D543B786E276B4136' => 'Unsorted',
'B9B603BEB19CFFC1653F2CB4E3DBE039' => 'Unsorted',
'3FFA720657A37ADE5CF8E05C5AE051EC' => 'Unsorted',
'998435EA75F039525F05DAE61562D672' => 'Unsorted',
'6EE5C59843E1A687CAB2408327943AFB' => 'Unsorted',
'38EA95055DA2FEFE757392F5FE8C687A' => 'Unsorted',
'B59A05EBCAF1F59F7EBEA7EB409294EF' => 'Unsorted',
'8611FFCC6812ECFF458A3ACD9678CB4A' => 'Unsorted',
'71B865A86463F181F39DFA18EA22AB51' => 'Unsorted',
'CA63C12DC5525987FD2F9F07D6018BF1' => 'Unsorted',
'F1823613691EBC53FB9C1F8AA89AC9FC' => 'Unsorted',
'39768155CE81EAD2E8A72FE2D4732A7E' => 'Unsorted',
'154E3493CA5CC4D0DD3B587B9748551C' => 'Unsorted',
'98F43409D1CD91F32C24164F9FD70B93' => 'Unsorted',
'68D59DE436701B2A9B04158116387CE5' => 'Unsorted',
'0749135D85D0F5B67E107D9BEC4F513F' => 'Unsorted',
'0CFB5D65CB4A30440175AD6F8AD98A5F' => 'Unsorted',
'EF46BBCD6A8405305BEC3AE0A7FCB410' => 'Unsorted',
'C6E142FFF29F5DACDBBF56779C0F32C7' => 'Unsorted',
'4A19DBB451063FC27B23AAC4F377AB3A' => 'Unsorted',
'E67A4D209BBDEE902E8E7A3F48931B71' => 'Unsorted',
'7FB7B15F9A1E7BF735F6B23EDDE2A0EE' => 'Unsorted',
'EF9C94719C4D6734603C6CDA456C15F0' => 'Unsorted',
'3864FD2937E166D9C5506F231049FC58' => 'Unsorted',
'97170AE9ACCD8C5F963F7A95AEEAE89B' => 'Unsorted',
'1473ACF31EF71B111F8563218E08D2B3' => 'Unsorted',
'F53B9FBA1C4663C2D65715705B7E3A98' => 'Unsorted',
'3744B53626C0B7DAC84E0331F1FC9211' => 'Unsorted',
'B0F0DAAF7ACC37031A640E70E40DBAB2' => 'Unsorted',
'6307E959CCC862298033A28E96DFCD27' => 'Unsorted',
'A89FDB4DABBCF2E3CBFA0585EDDCE370' => 'Unsorted',
'E59A8048346506C8C94165704BF086E1' => 'Unsorted',
'C57067F62BB5EAD2175062F0FFD373AB' => 'Unsorted',
'559A9EB15641989ADB22C1A3B017DCE2' => 'Unsorted',
'0B2840A296442D24C8AF921AC6D69C76' => 'Unsorted',
'C38AC278229F0B678B300E711FC79EFD' => 'Unsorted',
'0FF7584F806A4D89780E3C489713489A' => 'Unsorted',
'09104FD2E1B437000E5B27FEC7DF8F67' => 'Unsorted',
'634690713F08D6352DAE111E938FDB64' => 'Unsorted',
'40A867A0C19E04BFCEBF53DCB335C7A6' => 'Unsorted',
'974CDEA2E646758EF40D659957F6E93B' => 'Unsorted',
'7772192FC02919457D97537DD41900B8' => 'Unsorted',
'E056B25601DE15B90EFCF56CF9B3339F' => 'Unsorted',
'DFA57876B24FC22271BEB5AC8937E924' => 'Unsorted',
'1CDADCDFD160D79DBDDBAC1CAECD12BD' => 'Unsorted',
'A8A53E6D1D7CC28078F99C1F519C5137' => 'Unsorted',
'F2A59E52DD948322D2639B6F03B91A9D' => 'Unsorted',
'DECF5B1F722DE5C53A34C4158CBE0899' => 'Unsorted',
'D60A539456242BF009CCDD3ED6F21336' => 'Unsorted',
'580F02EB1B82B87AE9665F0516BB0CAB' => 'Unsorted',
'01E4E6278BC28848B1BAEEC701D55283' => 'Unsorted',
'70D3B68E0C728207406D480E4A3656FC' => 'Unsorted',
'557EAFDF7E797EA7171DEA9641374E5D' => 'Unsorted',
'EC8CDA8E16FB208D76AC299660E4135E' => 'Unsorted',
'B08D78746B93476FB5AD90D38EC930B3' => 'Unsorted',
'40C7028BB76300E8BE1A467E7E491C3F' => 'Unsorted',
'6F44BF83B6137567002D22FEB059499B' => 'Unsorted',
'D9F7A57ED93E336BFCC6B3C10D1018DA' => 'Unsorted',
'4DDEB486E7F07AF0558947760B9928EB' => 'Unsorted',
'E96DDFBE233480C63EEC6A92E9FD2ED5' => 'Unsorted',
'78AEC0F582573C5F75C5972CB473AD87' => 'Unsorted',
'E84D7FA526F13DDC259A860B021CE64F' => 'Unsorted',
'A3232FF40D3CB50488C90911DB286D8A' => 'Unsorted',
'2DBADC4A2DCEAC35F69A8E445491734D' => 'Unsorted',
'EDA9941C84763BB26BF975A579676EB9' => 'Unsorted',
'9A01E6AC0F70D4AE33ACAE0C6B17C66B' => 'Unsorted',
'1B3A78E7324C2A67AB8C219A5CFDA631' => 'Unsorted',
'46BD98E03E1EB4DEFCA388E1FF171DBC' => 'Unsorted',
'5C3A66364C4B9223D8F81BBB3EA93657' => 'Unsorted',
'6221A4E5C1282495C0C2B04E517B2BE5' => 'Unsorted',
'1613E6870249B26A525EB404A069B3E3' => 'Unsorted',
'19102D74D8388B80C05FDD5CB384B02F' => 'Unsorted',
'A4CA1AD225C64055FBA3CCD6518701A6' => 'Unsorted',
'4B1ADFF1B137EB2BCE88D3DC48881043' => 'Unsorted',
'55D6329A236ED0688F265B743B36A574' => 'Unsorted',
'AAB4E36F96CBC38F467916DA90CBEF50' => 'Unsorted',
'22A2421B0480C8B84035CD033ED5CE5C' => 'Unsorted',
'8CF2D3540A23145D62BD769EDB77BEDF' => 'Unsorted',
'E574ECD6A390C897109DCA694E60ACC1' => 'Unsorted',
'94FF8362CF30C910FA24DBF673B9F54B' => 'Unsorted',
'74888B1B3BE6167446DD8889F9578E88' => 'Unsorted',
'AC08B9D1C0E149DB8FF1F431F0FD0ADF' => 'Unsorted',
'EABC2FCCB6A55379899F15840186BC40' => 'Unsorted',
'0BC9354572D05D51486F22F9A3D978D0' => 'Unsorted',
'A42AAB01A041244E942E2FE41ECB8AC1' => 'Unsorted',
'953FF19CCAE42F8F968A254E0AAB121D' => 'Unsorted',
'699117B7ED1316E224962315699E0548' => 'Unsorted',
'5D97E236CA63742334FE5F4C27310E30' => 'Unsorted',
'A523B2F347A8ED163762272F0BE36679' => 'Unsorted',
'B8B1B877A986829250F4AEB8FA659EB9' => 'Unsorted',
'9F2AF0C15E675C0B050A54A40B098C7A' => 'Unsorted',
'80C625E852153E01515E520C127C9BFB' => 'Unsorted',
'93131FEDB860BB54C797D6DDAA03A234' => 'Unsorted',
'C85AABA6D749F06DD8185438618F06E1' => 'Unsorted',
'F57AF374CC32D73068C98BD9FF0886D9' => 'Unsorted',
'DC71941DCA41C933544BD63B4268AB26' => 'Unsorted',
'A8C484AA482B8CFD6B43B2978B245757' => 'Unsorted',
'4770E1703B1E89E4E6E50D45AB7DEDB7' => 'Unsorted',
'0A8A749721F6743D059648ED6BA7CAB1' => 'Unsorted',
'727554A737024D7C5222B86FE6AFE614' => 'Unsorted',
'1EFAC1E0C28112353D188A00EC92718B' => 'Unsorted',
'C07093BEF106EE5CD1C118421964B2D9' => 'Unsorted',
'49E66BF358F6FE758BC86EAAD7252329' => 'Unsorted',
'B9FA9B2128677D0A0147BB1779A846AC' => 'Unsorted',
'76A2B8344262EB0AC708B5DA2434C38F' => 'Unsorted',
'737FB2CA5BA8D4F9A57C4FC1F1687F12' => 'Unsorted',
'0249A9BCC68324076C2DF6B90ED357B8' => 'Unsorted',
'15CED1CD4EDE0B93E6462AA7906D4B26' => 'Unsorted',
'B27D3597EC55097658774D74F279771C' => 'Unsorted',
'847C8504BED50A3E7972366B5C61206A' => 'Unsorted',
'B5B239F497312162F8FE76B8950DB102' => 'Unsorted',
'1C0B77FDAA68712BE07903C45094BD84' => 'Unsorted',
'CED13CD98D03A9169160B4987F9DE870' => 'Unsorted',
'8AEFC1E5BC809F457DD2367B74FBCD72' => 'Unsorted',
'47CA0CDA845E68E939A16E341B59C014' => 'Unsorted',
'6B44D91221FBBDBB26AE422869ED4CBC' => 'Unsorted',
'69F29A65C675F81590CBEAC9191225AF' => 'Unsorted',
'91DC8C1EF2D1DAA213401673188AEEE7' => 'Unsorted',
'1F342C5D9C197CD72FCB3FA020ED6E14' => 'Unsorted',
'748259D883F273BA0E7A076F7A7D932A' => 'Unsorted',
'D787A4498C0798C4B55A688B9843BACB' => 'Unsorted',
'E06846301D65CD2E9C1829CFD2EAF47E' => 'Unsorted',
'B2DD13286198A6375F2878FC9B9E304F' => 'Unsorted',
'E33DCAA639B4DDCDB2E310787E9E53BD' => 'Unsorted',
'F825F0DDAB99E1D574F50C9A95F61B60' => 'Unsorted',
'E758C185481C6AC74E8B73A8FF684871' => 'Unsorted',
'B4B38147DAE1929E375E3BE6FCACEE58' => 'Unsorted',
'5888F186C7B1B5198F221806201CE7AC' => 'Unsorted',
'DAF2DCCA0752762E58E059F90D73F825' => 'Unsorted',
'2AF2F205E0944CBC32645D51E2CB8970' => 'Unsorted',
'041D949AEE6C7535751904F8E5DEF4EB' => 'Unsorted',
'58C727399D7692E97DDE1443696F0F5B' => 'Unsorted',
'983D9938CEA6E8319FECE6881AB8B329' => 'Unsorted',
'FCC0998C9F202D36EBA18CEBAB6B915C' => 'Unsorted',
'299F1749AB83462368A51116DBC38E1A' => 'Unsorted',
'D2A1B86D18B1BC446E1340D367FE3DCB' => 'Unsorted',
'9BB495F34896F163648704B16738FCEB' => 'Unsorted',
'309F0F052CBF85B3B52B0A7085AD1BF8' => 'Unsorted',
'CAA748E4C7AA6306BFD20D528E5901D4' => 'Unsorted',
'439AF92E9A8F33BAB4B3C8BB7313E726' => 'Unsorted',
'478BEAAE4F24E8F2865F75AE48803BA4' => 'Unsorted',
'35F2A71DFD7A2B372F70EDA000FAE302' => 'Unsorted',
'A897B926651EA77EFA8A6E13C112F2F0' => 'Unsorted',
'BD1C1840B5A43DA218E28725FE7425BB' => 'Unsorted',
'76C5F4B46FFCC8E5108F07D4848E403C' => 'Unsorted',
'786EAD8522E40ACBC1AE2B43BFE2091A' => 'Unsorted',
'29B8206871658CEB94114C6EBE051CDF' => 'Unsorted',
'9633EB48774A55AF646F0E9459C193EE' => 'Unsorted',
'00941D7ED5A4FC13B98B89EDEBE05D7A' => 'Unsorted',
'D31A17095353508C43E3035D05DB2B7C' => 'Unsorted',
'2339B25EBA47CA07CE7064A8EB5B6328' => 'Unsorted',
'CFD1F37896112F1399CE02ABEFAAE839' => 'Unsorted',
'AE890B2B996CA54E5D919353411F6BE9' => 'Unsorted',
'405CDC7E6BEA10499ADD7E9936D70E6B' => 'Unsorted',
'010CF52C1947997D2C44473726116305' => 'Unsorted',
'B0EFEF24F3743F2FAA5D2935CAF1661D' => 'Unsorted',
'28957D99BB89D6AE43D9720132567D20' => 'Unsorted',
'B55911C3C81CEF9C65EBC2767C913BAD' => 'Unsorted',
'5E5169D5A1CA9AA78C2B5C1041132F88' => 'Unsorted',
'5C1D29AE4D74AE5553FDBAAC2BC4BC79' => 'Unsorted',
'71B7A317AB813E1280BE2528E1BB2C0E' => 'Unsorted',
'3A611FCEF831F9C2BD45BCD2F274B750' => 'Unsorted',
'D446747780AF971473F99FC80FCF4D9B' => 'Unsorted',
'6DD672E924DC8E0F2FDFA267742B410D' => 'Unsorted',
'7715D693099950461D43857775A3E466' => 'Unsorted',
'ACCD7F5DD8DD9B75F9FD47BD4FFB4D71' => 'Unsorted',
'67CBA02EFA062F135E7D712D7CD708D0' => 'Unsorted',
'561D2D11049851832DED88B9BBABB4C0' => 'Unsorted',
'14ED0E36AC59BDF646AA9128494CB3A6' => 'Unsorted',
'C88D117FCD3D188FE7A4A0042B39CD3F' => 'Unsorted',
'D2475C95ACEA6561F98E5A5BC8B6C574' => 'Unsorted',
'830661B8758A078183E94A4EB4AAFE62' => 'Unsorted',
'36F9FB03CF58DB880291B36CD0395804' => 'Unsorted',
'043A5257A561DEEE5DEE726C7113E9BF' => 'Unsorted',
'008587623490D3C26D42F8677393D77A' => 'Unsorted',
'AAAA2CD1E7E32B8594ABD3ED13E17E9E' => 'Unsorted',
'7DE97BDE48E6E0F6AF0D3033CBD0D5B8' => 'Unsorted',
'99D0C9DC667C43C6DF8096E059F21791' => 'Unsorted',
'E68328243F54B8BFB1B33C509AB37EFC' => 'Unsorted',
'99D49C42D68B43973766CEEA6534B9ED' => 'Unsorted',
'B2C245FC62B3BEDAF2647BAB2C58F8B1' => 'Unsorted',
'461FFFC858DFB26D0D8B5D58CB80AA83' => 'Unsorted',
'5F47FDEFAD2949D534A55A6D9BB5661B' => 'Unsorted',
'15C630F1EF0F70F968829783F34BBB4F' => 'Unsorted',
'02F2E228A865E55DECEA5CAC8EEC88DB' => 'Unsorted',
'4746AC87C97CAAF2225BAE432B813142' => 'Unsorted',
'6C5884658DA2D12D41D5F7A1F690792A' => 'Unsorted',
'4E8195FBF32E506956007DE975B5A35C' => 'Unsorted',
'A974F88457424AC6D8E262DBF3ED7AA0' => 'Unsorted',
'BC6B000F5AC5DB94DAEE47720D0BFE6B' => 'Unsorted',
'413B0666736E87929B346CA2B712284D' => 'Unsorted',
'73447ECD4E8CBDA29EB45280328819FE' => 'Unsorted',
'30C714F4DF3FB9AB75985681A10EBE0B' => 'Unsorted',
'04263C5A19EA73CBF9407182C1AC14DB' => 'Unsorted',
'2E7E5011EFFE3E1F1776070BF56E9FEB' => 'Unsorted',
'96EF49CF824DCDF09F819E69A9D3DFE0' => 'Unsorted',
'CD50B269ED72D5C10A9C2889A8999257' => 'Unsorted',
'5FC96E3414F3C4E37FE603841157CC93' => 'Unsorted',
'7109B4F4B279BD82371D3E3B295B5F1F' => 'Unsorted',
'484365B64CAA636E60C3AA98EFA518E1' => 'Unsorted',
'B254FD4BEAE454FBA4CF04FA3C667CCB' => 'Unsorted',
'DA21A9ADE71C8232A68D9DE779CA8C32' => 'Unsorted',
'154D78CDB0E326B86D6754DBE1EDB948' => 'Unsorted',
'CDAA4F89BC2363D34530EAF6BB1E2281' => 'Unsorted',
'BD89984B493ECE385DA32BD768FDFC9F' => 'Unsorted',
'894DD7454AA096BCC769DA56C2D4C0E0' => 'Unsorted',
'6FCBC48B65AAC48C902629A18286D943' => 'Unsorted',
'D4C1596BCC14D1D5DA9169E6F2C93120' => 'Unsorted',
'5B45121F6E3E9DFAB7AD0765E5D6A14A' => 'Unsorted',
'B7FA8A82B3865B7DC830CCB8A34595AA' => 'Unsorted',
'3C47D0A4FA0E78264694D8F48B94AC66' => 'Unsorted',
'26A33B36DD6CAA076E0FA907047A2631' => 'Unsorted',
'A0827D76F362D303A25A3103156F5B70' => 'Unsorted',
'7548E3C63CC2CABE38CDA3ED25C26F87' => 'Unsorted',
'4AD31C47E7A2348C75A24B15135F9BF7' => 'Unsorted',
'DF983936617E156C7B25DBA6D55C6F78' => 'Unsorted',
'9819C9E6EE9C7F81BA291E8D15E3ACF2' => 'Unsorted',
'F83E05F3F0109E3CB11ABEDB952B5F2E' => 'Unsorted',
'8543BDCA2CCF99A60DA717EBE9F768C4' => 'Unsorted',
'8341337B8D4167C4F93720A08822ED9F' => 'Unsorted',
'A16A4D50D2F92C4D7AE43B174DC47706' => 'Unsorted',
'1E9C84755EC25513A790837F4C853FA5' => 'Unsorted',
'D957515B90A80F5B09AEE198F8A936C1' => 'Unsorted',
'9E2B7037D86B99AB02D783B7E2E5E8D7' => 'Unsorted',
'68FA90750210421AEFFBE7BB3F528171' => 'Unsorted',
'6E1CC075ABE11A977ED30633A509C24E' => 'Unsorted',
'767D5CF6AEE8F968B158FE9C2220435B' => 'Unsorted',
'9F96D7E7B885ADA4C22F710D95834061' => 'Unsorted',
'E6359FDB5404D429BE5CE493169194D2' => 'Unsorted',
'D061A89FB89AB172937006771812B28A' => 'Unsorted',
'D7C539567E486BB22A72C63D19AD42D8' => 'Unsorted',
'393B842D0F725096D49DF9BA2B7E4598' => 'Unsorted',
'602ACD4B21AD6AC8E894DC8DB288C6AB' => 'Unsorted',
'F90CEE182FFA4CF38EECD6FCE9168AB1' => 'Unsorted',
'EE6D4F374D103B0597D13C704368394E' => 'Unsorted',
'128CC2CDC5986C3C9F4DD56E74DEF184' => 'Unsorted',
'CB7EC40C9893CA62CF846FF0F4C27F30' => 'Unsorted',
'EC88082657FAE838EB2194B67C92A187' => 'Unsorted',
'4634C0633DC83965F4FB6192C0C0720E' => 'Unsorted',
'8D206C526AF5943020942DCC1F351A74' => 'Unsorted',
'BA8BF9D8C3477AC4D9E96CDE01D6D4FB' => 'Unsorted',
'4AEE9A65BF340CC3860C9FD299885086' => 'Unsorted',
'3E54D40C05458CAE7ACD0936942A9657' => 'Unsorted',
'1F972A1F803DE63BDBC6CE92AC8FC199' => 'Unsorted',
'28C2AA9112D875FC77D907A1658FE94D' => 'Unsorted',
'B4642450399A338282E6355899F98B5B' => 'Unsorted',
'079B218624983A1D864B33F2A2A503E3' => 'Unsorted',
'CA61237AA2EF64EAA638BADB0C5E7FB1' => 'Unsorted',
'F53F8382A4D2229E0E102B7A64063CA3' => 'Unsorted',
'7CF807EF5976931E733691B6F5EFF7CF' => 'Unsorted',
'5735217EC885CD474F062953AE075644' => 'Unsorted',
'3823882072F8E984BC7C9A4AA0254296' => 'Unsorted',
'F80BBD2D06CA56B919B5B073C7E53979' => 'Unsorted',
'D03DF023FFBB6491D047B7E23236283A' => 'Unsorted',
'3A5B8431997CC655EEC6E08B04AD65CF' => 'Unsorted',
'6C4C3CE9AA21864EA64CD9A9AD5E5C7E' => 'Unsorted',
'8EC1208585D367BAD1D9B89DB6B8ACF7' => 'Unsorted',
'B86A20657203F03CACFBFF3433F8C2A8' => 'Unsorted',
'F8BA64550C819EA3E2CFBA069BD68C67' => 'Unsorted',
'FA0AC8FFDCC06A8C39179017F150BA88' => 'Unsorted',
'3D29E92B10030900E2DB8968956611E8' => 'Unsorted',
'9E8E3D2941E450BC3EF31DC70118063D' => 'Unsorted',
'3693449E5C95A4B745CE21FB8016B6EA' => 'Unsorted',
'A2227BC01383DD107D4E9A93AEFF9035' => 'Unsorted',
'AAB0B5E0E206AA9B919E9B84DFA283EC' => 'Unsorted',
'D9045762F487268D346E11DCC29BF697' => 'Unsorted',
'559996552D855C5B6386D8EF99134051' => 'Unsorted',
'846119D645909060A441F475FBE438D0' => 'Unsorted',
'87827A3336F862F0E7253EC45DDCE989' => 'Unsorted',
'4FCEFA3CFB8D731E90B53FC949151C91' => 'Unsorted',
'A257F8CCA77A6CB4E219488E86BCE794' => 'Unsorted',
'3ADACB60B0C3440791C02BE2048229B9' => 'Unsorted',
'EAF6B57BF2DAC94523446123DA696B93' => 'Unsorted',
'96DD3D4044944568E8E712F7B6A03423' => 'Unsorted',
'2885D973933190FB79F7C4DFDEC07CB0' => 'Unsorted',
'91FCCD765F3FDF2E2FCD020B7ADD3528' => 'Unsorted',
'1485B63F2A7AD71E0C08F938BE145D5F' => 'Unsorted',
'E4C5E0291E623B7742FA34180E6DF78D' => 'Unsorted',
'820FC3766D64D5504C0FA29A5D82F57E' => 'Unsorted',
'C8A9F4DC766FDCF833B3229519071DD7' => 'Unsorted',
'B765846D0E7F1D57F30094A97E7AB43E' => 'Unsorted',
'58F8FB43E70C6F05F9C760E57003B01A' => 'Unsorted',
'653BB23FA6526C976C64449E3EED7594' => 'Unsorted',
'0C6CD628B7294376C9E2A450AC054642' => 'Unsorted',
'F6ED302112FDED20FD4F6E4CA985003F' => 'Unsorted',
'7485A40C8568C1142BA5F60613290372' => 'Unsorted',
'31796E12C4BFD5BCF9A9641AC1E7E402' => 'Unsorted',
'AF5B8BB998E9CD7998ACAD92DF0B34BD' => 'Unsorted',
'5991AE956AFD3819F306A4DF11F55361' => 'Unsorted',
'20240BD07C4BC8B15EC27BB0F860A436' => 'Unsorted',
'8C868F3AA912F9657572EC33D3300766' => 'Unsorted',
'D63A966D32D17551E04D8E0DE82911F8' => 'Unsorted',
'4474E75E93D66E15377339F96A5D13F2' => 'Unsorted',
'5EDDCB4FC1AF72E22DD06E49D7C613AC' => 'Unsorted',
'5E266290B6A7869D584AD65395446D43' => 'Unsorted',
'7EA3D70E22D61E97998BEFB420B3E7DE' => 'Unsorted',
'6CE56CC2BD4238E831E9A64E4547A81B' => 'Unsorted',
'0FD3506E12553B4B2AF482D99DCDB0B4' => 'Unsorted',
'16A6744E5D6BD91E926566222463C211' => 'Unsorted',
'B31F2B5D7C93BCEFA4DD47ACD492ADDD' => 'Unsorted',
'84D2CFFFC6C85724374AF43C67833793' => 'Unsorted',
'2B25F94A437653288FDAEF00F01EEDDD' => 'Unsorted',
'6972DC45CE36186E0ECC13D6D54E2DB6' => 'Unsorted',
'D5A194AF4965159101619370E2989E9C' => 'Unsorted',
'CE1CECF9844CB17B5AFE5FA738D564F4' => 'Unsorted',
'9BA3BF1B58A2CC129B728CF7D0D71DAD' => 'Unsorted',
'10E066280194FA824A0665F02BFAB2F3' => 'Unsorted',
'89449A27BC1DA3220BB8EEB876E2EFB5' => 'Unsorted',
'C62BCD20484A6F61280970F3D9DD8935' => 'Unsorted',
'1AEC9911A867D4525A1A9BC2D9BE7C31' => 'Unsorted',
'B3D7874BF265BEA925531D4B6FD84575' => 'Unsorted',
'60C3DC9D3E809ED834C0039E4BF81D24' => 'Unsorted',
'020F4E532D1BE2929487B2AE219CC57A' => 'Unsorted',
'2AE565174A3D0A6E99F12C2DF7A45D0F' => 'Unsorted',
'EB2D3383728D1E3A50808B2A799F6D76' => 'Unsorted',
'17C398C14C2490A23D78182E4F8FF379' => 'Unsorted',
'19F5FFFB2CD070E085EFECCB9AEB22AB' => 'Unsorted',
'F1922A317C351832F416E212B977BC51' => 'Unsorted',
'1E2ED479703EB69FEA5912CF542ED3F5' => 'Unsorted',
'3032BECB23EF5C86C2C9B39BC939A516' => 'Unsorted',
'E85DC148D126590EBD108DDD22FCFD13' => 'Unsorted',
'6FD92EE2DF462878CE1074391750AF03' => 'Unsorted',
'B2DB0F013C318BBCAB1541B2C54D24E8' => 'Unsorted',
'EE12F722C50A7F86043892B61EB16A55' => 'Unsorted',
'C0308421307E2105007B4ED0E819B84A' => 'Unsorted',
'E8EAA4B791E6D774470CBFC045897AFA' => 'Unsorted',
'50A4D84477894D1C24A35B4EEE2F6E53' => 'Unsorted',
'A74A45F64DD1B4B09E05A4426E940B7D' => 'Unsorted',
'4915C575CE9E0C8BD7898E652E23B37F' => 'Unsorted',
'33A44E3DC83BDD02C6E184189D55C808' => 'Unsorted',
'B01EB2C9C594BCB604F801D2B1E2A32C' => 'Unsorted',
'4DF49962BC7B18E90AE9F3952444587B' => 'Unsorted',
'B2DE5B2C2BEDCE7C77BEE8A08F42DBE9' => 'Unsorted',
'E1C2A42CAF78A0E6DA97DF52D6FAED55' => 'Unsorted',
'54AA1F0FF3F10F9806544C8E38E5ED3F' => 'Unsorted',
'9BCBAE93E8D123B8CDF02A33B5106AC4' => 'Unsorted',
'38F02B606B50E9AC3401C23620B619C6' => 'Unsorted',
'6871BFBCBBE458D06DCC71746A0A4C77' => 'Unsorted',
'EBDB8D9CF82DC1F53ED1EAAC39851F6F' => 'Unsorted',
'9851B18D618BFF93C5FC07743FE8CE09' => 'Unsorted',
'9AFFA2C5F1C4DFA1DE883EE106BFAB14' => 'Unsorted',
'910086EB648991EBE7AE862D93932F36' => 'Unsorted',
'7A2595AECEDE95C9338C710CF8DBBA99' => 'Unsorted',
'C7BF42F12A3EE32E694EB9FE46E1DB51' => 'Unsorted',
'C8777688BF00F42E6C73DE336E10A25A' => 'Unsorted',
'54490521B6965BD0E95D93928C1B4056' => 'Unsorted',
'CF08E9B3421E4B1AA665717C555ED670' => 'Unsorted',
'964A28D0F0E6AA3423A4FF1DA4598C21' => 'Unsorted',
'7D71C9C119989446766442E8127BA0CB' => 'Unsorted',
'92913EAD973B8AA24BFF4F38FE66927E' => 'Unsorted',
'7E9938FF024C809DE3CC950B61E01F6B' => 'Unsorted',
'8C3DF66C7BCFCB291221884EE46CB351' => 'Unsorted',
'A60518DDF46B904E7F8B4ADC96F60342' => 'Unsorted',
'07DDFE013304965BF7EB63D9AC5BD0C2' => 'Unsorted',
'A237F20A0491149B1C0890B0FCE8E0CE' => 'Unsorted',
'7D20C0D5F382EEB31E6B830EA1ED4B8F' => 'Unsorted',
'5A219A19D772E26F41A86BCB8449093E' => 'Unsorted',
'4E78EA91BE73C71012930C4144B50CC1' => 'Unsorted',
'200A67508DF9C6B2F47A7A93FF2160CA' => 'Unsorted',
'C0C71AE21AEC6A6116464B8A7DF4D534' => 'Unsorted',
'9DBFDC3B026622E83398554B783E1CEC' => 'Unsorted',
'D5F6040AAB1B27E29461E847CFFDA08E' => 'Unsorted',
'F1142B43BCD76C0EC9A0CBF1BE8BE407' => 'Unsorted',
'4A1A74DF0A5B00A61DEC37A8C8286263' => 'Unsorted',
'E215BBE20C75E4919196640879881A26' => 'Unsorted',
'C10FF08AB773CF83BCAA06F9A6246277' => 'Unsorted',
'5D55ED8CC0F32AD2C7322A5EBB420E6E' => 'Unsorted',
'F6466625E47FEA62BF00295354B4717E' => 'Unsorted',
'1370951C77A785487535422491DEBFBB' => 'Unsorted',
'10064D052928ECC127D2E7C20163AF4F' => 'Unsorted',
'8C3389C72D0D8ED733A6CC0B943E593E' => 'Unsorted',
'66664EB6C3D049036FE03BDE6627EA2C' => 'Unsorted',
'CD99977E922FD138838A595696C6F600' => 'Unsorted',
'E314E10E8F07669755425EFD617E5049' => 'Unsorted',
'34060F16A1019793A18A6FE8C3676DC3' => 'Unsorted',
'31AF0DDAD2E281455035F4EC8C2F7E92' => 'Unsorted',
'FAA62CA76F55D9170AF9A9A80CA58775' => 'Unsorted',
'5947125D2F4D18473CEB373A14541AA8' => 'Unsorted',
'E0FA832384CA01762F83E963AE124335' => 'Unsorted',
'E178A9EFFEF55745275E6FBD3506C75F' => 'Unsorted',
'126A9991440EB2F25B63FBB1A249685D' => 'Unsorted',
'08C6C5A182C1E5174F45988BD7877461' => 'Unsorted',
'570CBFCA00FFBCEF24C7F5C6789FAA43' => 'Unsorted',
'C2FE27A86B3174685B5BB15917F27381' => 'Unsorted',
'38B9881CD317734B345E10C1FBBD8D45' => 'Unsorted',
'D61B975E4C6A241C4B0E9D59882EDCF5' => 'Unsorted',
'D2E495C8ABFA7A2B70E70FE4C67CD764' => 'Unsorted',
'7B558127CCA04DC3031453AEAEA36066' => 'Unsorted',
'64FC261EBBC3FFC30A7EC2AD46D07EE4' => 'Unsorted',
'81528F4D891DBA400BE90CD49C91DE51' => 'Unsorted',
'0D9CD8E0E43F23E31D441B22BF46EF08' => 'Unsorted',
'22234913192677D47FA0E2BE8F0C92D4' => 'Unsorted',
'CA65A513F5EF6386CEC04F8905887C76' => 'Unsorted',
'CDB8132DFBC00B4AD4E71A24C6E2E819' => 'Unsorted',
'A793201762A3FE35DEC4A5F702D9F2DC' => 'Unsorted',
'EBBD103489AC59E25625C30DE3146EDA' => 'Unsorted',
'173E958B5D8E8DCEAD291367D98B30B3' => 'Unsorted',
'61EAF194B1B8F3BBA8BBC95365107F43' => 'Unsorted',
'EE554AFAD3E3977C45162859E83B58A5' => 'Unsorted',
'0120379B8A947AB676646CC8E4247734' => 'Unsorted',
'88634125E5F3F65C949372A9369D2B74' => 'Unsorted',
'CB23375AB6EA359B2B4B35EE8B9B76D4' => 'Unsorted',
'D63C82F101B17E131A522EE4FCE9BACD' => 'Unsorted',
'D8816389C27EC666558B712B7B1D5726' => 'Unsorted',
'D298594B92388B82F558EF0806CF47DD' => 'Unsorted',
'8C41264BF2D6BD2D03543584D374E4C8' => 'Unsorted',
'6AB2F344EEDAB7D6C2A25AB36777F096' => 'Unsorted',
'1F0A9474293A9671C054C106A71329E5' => 'Unsorted',
'EDF767A4D8A77D30350D4296345817A9' => 'Unsorted',
'A9CDB060A36F09C2916080130BCB04C9' => 'Unsorted',
'39928662E23C332453AEAAE176CC8B5C' => 'Unsorted',
'8642C7891EA6A3D906619EE0E68CBD9A' => 'Unsorted',
'87C511E4FC9E51FE6B424A09A409DFEC' => 'Unsorted',
'08B3C78AE3139BBBF9D867B21A27BA42' => 'Unsorted',
'EA6E51CBB8EA4B405615AA069FC16737' => 'Unsorted',
'AA6D5D03EB54B4BDFB43F2EB1C0DB502' => 'Unsorted',
'061A7129305A3230AA2FB550BD71FA9E' => 'Unsorted',
'ED7BF3C4C44305DB293E931A8270F0B5' => 'Unsorted',
'4D5EA9135953FCA17B8FA8D28E9DD740' => 'Unsorted',
'06E8391D3A495B390E46D42687C654B0' => 'Unsorted',
'F6C5E579925AF0A360D464D0F573C699' => 'Unsorted',
'665BFCEF05E87CFA16BA30302F75A158' => 'Unsorted',
'BF728DE7E44B7308DFD81F6B507DF253' => 'Unsorted',
'B009C56D8AB60CC8BAF91ED0364A0E98' => 'Unsorted',
'91C7B73B6A594A753BBD075126F55219' => 'Unsorted',
'92DA9DFDA777AD06C68D35190EFA1B35' => 'Unsorted',
'09A1D434DBD7197E7C3AF8A7C28CA38B' => 'Unsorted',
'DFAA6370B4E3EA383327A56A67FA35F2' => 'Unsorted',
'B4AEEDDAF596FAF6B9B26A6FB676FB2E' => 'Unsorted',
'AE7949DE210FBB0F3DA4199E17B1D72E' => 'Unsorted',
'70ED8160B907CCD7E6BC33EAE0997F5A' => 'Unsorted',
'09106EFE2ED597172C451D2BFADB2EE3' => 'Unsorted',
'0F00E00167244FD0E5B470097DFA6D0D' => 'Unsorted',
'0686E7B14C9C2166E00406CD79DED82E' => 'Unsorted',
'C9BDF248187538D4DE16EE443A0857AA' => 'Unsorted',
'7708274F38B014B10C46B36A29762DB2' => 'Unsorted',
'6D0C60A48C2EA5CFBD5C10EAC7EE8EA3' => 'Unsorted',
'CC012E06235AF843B431587CA1CEEF7A' => 'Unsorted',
'31F2C82C3F9086901F5D9E305F86D7F1' => 'Unsorted',
'71C0CADB8DE44FF9C1E38EFFC10909C8' => 'Unsorted',
'94D63329C8D30764377D08759FC65259' => 'Unsorted',
'3908514A276EE12A677857586DBBCE69' => 'Unsorted',
'0365333888E959085F590A3B6CCFFF75' => 'Unsorted',
'B5F54D9A11D1EAE71F35B5907C6B9D3A' => 'Unsorted',
'FD89A7CAC2B314F0C3DAD6BF36E4CA59' => 'Unsorted',
'0947ACE1746DA69BDFCE895DD1EB4D33' => 'Unsorted',
'FA2C3A8EC070D3234EC29F27FD081DC3' => 'Unsorted',
'03B8CEA2B8859558D1D2B0F6FB76F1C8' => 'Unsorted',
'2F3533B9319F61EAC9AAAFD07D819D0B' => 'Unsorted',
'No_MD5_Availiable' => 'what'
);

my %auth_id_list_nn = (
'1070000022000001' => 'what',
'1070000023000001' => 'what',
'107000004C000001' => 'what',
'1070000020000001' => 'what',
'1070000025000001' => 'what',
'1070000021000001' => 'what',
'1070000037000001' => 'what',
'1070000043000001' => 'what',
'1070000024000001' => 'what',
'107000001F000001' => 'what',
'1FF0000002000001' => 'what',
'1050000000000001' => 'what',
'1070000000000000' => 'what',
'1050000000000000' => 'what',
'1FF0000001000001' => 'what',
'1050000003000001' => 'what',
'10700003FC000001' => 'what',
'1070000501000001' => 'what',
'1070000055000001' => 'what',
'1070000002000001' => 'what',
'1070000039000001' => 'what',
'10700005FF000001' => 'what',
'1070000001000001' => 'what',
'102000003C000000' => 'what',
'1070000058000001' => 'what',
'1070000059000001' => 'what',
'1FF0000000000000' => 'what',
'1010000001000003' => 'retail games and their updates',
'1020000401000001' => 'ps2emu',
'1050000003000001' => 'lv2_kernel.self',
'1070000001000001' => 'LPAR 1 or HV processes / SCE_CELLOS_PME',
'1070000001000002' => 'onicore_child.self',
'1070000002000001' => 'LPAR 2 or GameOS / PS3_LPAR',
'1070000002000002' => 'mcore.self',
'1070000003000002' => 'mgvideo.self', 
'1070000004000002' => 'swagner / swreset', 
'107000001A000001' => 'ss_sc_init_pu.fself', 
'1070000017000001' => 'ss_init.fself',
'107000001C000001' => 'updater_frontend.fself', 
'107000001D000001' => 'sysmgr_ss.fself', 
'107000001F000001' => 'sb_iso_spu_module.self', 
'1070000020000001' => 'sc_iso.self / sc_iso_factory.self',
'1070000021000001' => 'spp_verifier.self',
'1070000022000001' => 'spu_pkg_rvk_verifier.self',
'1070000023000001' => 'spu_token_processor.self',
'1070000024000001' => 'sv_iso_spu_module.self', 
'1070000025000001' => 'aim_spu_module.self',
'1070000026000001' => 'ss_sc_init.self',
'1070000028000001' => 'factory_data_mngr_server.fself', 
'1070000029000001' => 'fdm_spu_module.self',
'1070000032000001' => 'ss_server1.fself',
'1070000033000001' => 'ss_server2.fself',
'1070000034000001' => 'ss_server3.fself', 
'1070000037000001' => 'mc_iso_spu_module.self', 
'1070000039000001' => 'bdp_bdmv.self', 
'107000003A000001' => 'bdj.self',
'1070000040000001' => 'sys',
'1070000041000001' => 'ps1emu', 
'1070000043000001' => 'me_iso_spu_module.self',
'1070000044000001' => '(related to usb dongle)',
'1070000045000001' => '(related to usb dongle)',
'1070000046000001' => 'spu_mode_auth.self', 
'107000004C000001' => 'spu_utoken_processor.self',
'107000004F000001' => 'unknown',
'1070000050000001' => 'unknown',
'1070000052000001' => 'sys',
'1070000054000001' => 'unknown',
'1070000055000001' => 'manu_info_spu_module.self', 
'1070000056000001' => 'cachemgr.self',
'1070000057000001' => 'EBOOT.BIN.self + .sprx files',
'1070000058000001' => 'me_iso_for_ps2emu.self',	
'1070000059000001' => 'sv_iso_for_ps2emu.self',
'10700003FC000001' => 'emer_init.self', 
'10700003FD000001' => 'ps3swu',
'1070000409000001' => 'pspemu', 
'107000040A000001' => 'psp translator',
'107000040B000001' => 'psp modules', 
'107000040C000001' => 'psp emu drm',
'1070000501000001' => 'hdd_copy.self', 
'10700005FC000001' => 'sys_audio', 
'10700005FD000001' => 'sys_init_osd',
'10700005FF000001' => 'vsh.self',
'1FF0000001000001' => 'lv0',
'1FF0000002000001' => 'lv1.self',
'1FF0000008000001' => 'lv1ldr', 
'1FF0000009000001' => 'lv2ldr',
'1FF000000A000001' => 'isoldr',
'1FF000000C000001' => 'appldr', 
'1070000500000001' => 'cellftp', 
'10700003FE000001' => 'sys_agent.self',
'10700003FF000001' => 'db_backup, mkfs, mkfs_085, mount_hdd, registry_backup, set_monitor',
'1070000048000001' => 'ftpd', 
'10700003FD000001' => 'PS3ToolUpdater',
'N/A' => 'what'
);

my %ros_not_self = (
'6372657365727665645f30' => 'what',
'64656661756c742e737070' => 'what',
'65757275735f66772e62696e' => 'what',
'706b672e7372766b' => 'what',
'70726f672e7372766b' => 'what',
'73646b5f76657273696f6e' => 'what',
'N/A' => 'what',
);

my %ros_filetable_versions = (
'361.000' => 'what',
'342.000' => 'what',
'340.000' => 'what',
'330.000' => 'what',
'260.000' => 'what',
'253.000' => 'what',
'245.000' => 'what',
);

############################################################################################################################################

my %target_id_list  = (
"80","AVTest / DECR / TEST",
"81","SD/DECR Ref Tool",
"82","Debug / DEX",
"83","Retail / Kiosk Japan / CEX J1",
"84","Retail / Kiosk USA / CEX UC2",
"85","Retail / Kiosk Europe / CEX CEL",
"86","Retail / Kiosk Korea / CEX KR2",
"87","Retail / Kiosk UK / CEX CEK",
"88","Retail / Kiosk Mexico / CEX MX2",
"89","Retail / Kiosk AUS/NZ / CEX AU3",
"8A","Retail / Kiosk South Asia / CEX E12",
"8B","Retail / Kiosk Taiwan / CEX TW1",
"8C","Retail / Kiosk Russia / CEX RU3",
"8D","Retail / Kiosk China / CEX CN9",
"8E","Retail / Kiosk Hong Kong / CEX HK5",
"A0","ARC / Arcade"
);

############################################################################################################################################

my %idps_list = (
"06","CECHHxx or CECHMxx (DIA-001)",
"07","CECHJxx or CECHKxx (DIA-001)",
"08","CECHLxx or CECHPxx (DIA-001)",
"09","CECH20xx (DYN-001)",
"0A","CECH21xx (SUR-001)",
"0B","CECH25xx (JTP-001 or JSD-001)",
"0C","CECH30xx (KTE-001)",
"0D","CECH40xx (MSX-001 or MPX-001)",
);

############################################################################################################################################

my %bootldr_revision_key_list  = (
"065B860C5CF76AC4598DD7B4","CECHE/CECHG (COK-002/W/SEM-001)",
"89EFFD15B3850E3B2A734484","CECHG/CECHH (SEM-001/DIA-001)",
"6EED04A04E41532AC123C718","CECHH (DIA-001)",
"E644A075B60B7996C1297AA0","CECHJ (DIA-002)",
"7B09CBEE002FAF5159F8D5A8","CECHH/CECHK (DIA-002)",
"ED4C79D65D602876FFADA6FD","CECHH (DIA-002)",
"B19434A33CF1C866DF420E50","CECHL/CECHP (VER-001)",
"83EFB976C4DED135327CD377","CECHL (VER-001)",
"92AC2C2157A577C84DDFECDB","CECHL (VER-001)",
"41F793C709418F938944BA7A","CECHL/CECH20xx (VER-001/DYN-001)",
"FA46EC86570FCAAA064E8A86","CECH20xx (DYN-001)",
"F5A221B5C05F214201979DAA","CECH20xx (DYN-001)",
"7780B134B6DF258A1ABBAB4D","CECH20xx (DYN-001)",
"CB9E152428B44FD2F93FBC43","CECH25xx (JSD/JTP-001)",
"EFB3455D6A9FD751005E34BC","CECH21xx (SUR-001)",
"53921CE7F73341769B7A1ED6","CECH21xx/CECH25xx (SUR-001/JSD/JTP-001)",
"53E6A0BBB0AFA20067D0B39A","CECH25xx (JSD/JTP-001)",
"AA3AEA6E3DA09A581E1E2100","CECH25xx (JSD/JTP-001)",
"C5A42771EE5E219A3BFC2C45","CECH25xx (JSD/JTP-001)",
"13ECA74A8E14D473129128E8","CECH30xx (KTE-001)",
"2E604104D943D1B534D4C5F5","CECH30xx (KTE-001)",
"BBCCBF29ECD802844EB28AE6","CECH30xx (KTE-001)",
"1FDC1E2DF00DA36701E2F8F6","CECH40xx (MPX/MSX-001)",
);

my %metldr_revision_key_list  = (
"1362F2C2E6835D6FC144F246","CECHE/CECHG/CECHH (COK-002/W/SEM-001/DIA-001)",
"7822C41EB9F00FA4830A0B69","CECHG/CECHH (SEM-001/DIA-001)",
"5E1F9CED758B6B94442BF031","CECHH (DIA-001)",
"53E7EA237889AE20322A9708","CECHH/CECHJ/CECHK (DIA-001/DIA-002)",
"43B6EF4AE20F7400C8809E53","CECHL/CECHM/CECHP (VER-001)",
"BC78B8F02879A81184A0DA74","CECHL/CECH20xx (VER-001/DYN-001)",
"99873BC715F280809C302225","CECH20xx/CECH21xx/CECH25xx (DYN-001/SUR-001/JSD/JTP-001)",
"C3266E4BBB282E76B7677095","CECH25xx (JSD/JTP-001) Metldr 3.50+ Enforced",
"DBA53B0AB5181D971524615B","CECH25xx (JSD/JTP-001) Metldr.2 (3.56+)",
"6ED7BCD81F11EA34425F9B9D","CECH25xx/CECH30xx (JSD/JTP-001/KTE-001) Metldr.2 (3.60+)",
"39ECF2D2ACC0E0752248A9F8","CECH25xx/CECH30xx (JSD/JTP-001/KTE-001) Metldr.2 (3.60+)",
"C36C2E4300AACBE6F64FAD92","CECH30xx (KTE-001) Metldr.2 (3.72+)",
"EA838371878EF0892A5EF6B6","CECH30xx (KTE-001) Metldr.2 (3.72+)",
"A2834B1DFD969CC1769517C6","CECH40xx (MPX/MSX-001) Metldr.2 (4.20+)",

);

############################################################################################################################################

my %metldr_filelength_list = (
"E7B0","0E77",
"E8C0","0E88",
"E8E0","0E8A",
"EA60","0EA2",
"E8D0","0E89",
"E890","0E85",
"E920","0E8E",
"E960","0E92",
"F920","0F8E",
"F9B0","0F97",
);

my %metldr_binarysize_list = (
"0E77","E7B0",
"0E88","E8C0",
"0E8A","E8E0",
"0EA2","EA60",
"0E89","E8D0",
"0E85","E890",
"0E8E","E920",
"0E92","E960",
"0F8E","F920",
"0F97","F9B0",
);

############################################################################################################################################

my %ros_list = reverse(
"aim_spu_module.self","61696d5f7370755f6d6f64756c652e73656c66",
"creserved_0","6372657365727665645f30",
"default.spp","64656661756c742e737070",
"emer_init.self","656d65725f696e69742e73656c66",
"eurus_fw.bin","65757275735f66772e62696e",
"hdd_copy.self","6864645f636f70792e73656c66",
"lv0","6c7630",
"lv0.2","6c76302e32",
"lv1.self","6c76312e73656c66",
"lv2_kernel.self","6c76325f6b65726e656c2e73656c66",
"manu_info_spu_module.self","6d616e755f696e666f5f7370755f6d6f64756c652e73656c66",
"mc_iso_spu_module.self","6d635f69736f5f7370755f6d6f64756c652e73656c66",
"me_iso_for_ps2emu.self","6d655f69736f5f666f725f707332656d752e73656c66",
"me_iso_spu_module.self","6d655f69736f5f7370755f6d6f64756c652e73656c66",
"pkg.srvk","706b672e7372766b",
"prog.srvk","70726f672e7372766b",
"sb_iso_spu_module.self","73625f69736f5f7370755f6d6f64756c652e73656c66",
"sc_iso.self","73635f69736f2e73656c66",
"sdk_version","73646b5f76657273696f6e",
"spp_verifier.self","7370705f76657269666965722e73656c66",
"spu_pkg_rvk_verifier.self","7370755f706b675f72766b5f76657269666965722e73656c66",
"spu_token_processor.self","7370755f746f6b656e5f70726f636573736f722e73656c66",
"spu_utoken_processor.self","7370755f75746f6b656e5f70726f636573736f722e73656c66",
"sv_iso_for_ps2emu.self","73765f69736f5f666f725f707332656d752e73656c66",
"sv_iso_spu_module.self","73765f69736f5f7370755f6d6f64756c652e73656c66",
"sv_iso_spu_module.self","73765f69736f5f7370755f6d6f64756c652e73656c66",
"appldr","6170706c6472",
"isoldr","69736f6c6472",
"lv1ldr","6c76316c6472",
"lv2ldr","6c76326c6472",
"lv2Dkernel.self","6c7632446b65726e656c2e73656c66",
);


############################################################################################################################################

my %auth_id_list  = (
'1010000001000003' => 'retail games and their updates',
'1020000401000001' => 'ps2emu',
'1050000003000001' => 'lv2_kernel.self',
'1070000001000001' => 'LPAR 1 or HV processes / SCE_CELLOS_PME',
'1070000001000002' => 'onicore_child.self',
'1070000002000001' => 'LPAR 2 or GameOS / PS3_LPAR',
'1070000002000002' => 'mcore.self',
'1070000003000002' => 'mgvideo.self', 
'1070000004000002' => 'swagner / swreset', 
'107000001A000001' => 'ss_sc_init_pu.fself', 
'1070000017000001' => 'ss_init.fself',
'107000001C000001' => 'updater_frontend.fself', 
'107000001D000001' => 'sysmgr_ss.fself', 
'107000001F000001' => 'sb_iso_spu_module.self', 
'1070000020000001' => 'sc_iso.self / sc_iso_factory.self',
'1070000021000001' => 'spp_verifier.self',
'1070000022000001' => 'spu_pkg_rvk_verifier.self',
'1070000023000001' => 'spu_token_processor.self',
'1070000024000001' => 'sv_iso_spu_module.self', 
'1070000025000001' => 'aim_spu_module.self',
'1070000026000001' => 'ss_sc_init.self',
'1070000028000001' => 'factory_data_mngr_server.fself', 
'1070000029000001' => 'fdm_spu_module.self',
'1070000032000001' => 'ss_server1.fself',
'1070000033000001' => 'ss_server2.fself',
'1070000034000001' => 'ss_server3.fself', 
'1070000037000001' => 'mc_iso_spu_module.self', 
'1070000039000001' => 'bdp_bdmv.self', 
'107000003A000001' => 'bdj.self',
'1070000040000001' => 'sys',
'1070000041000001' => 'ps1emu', 
'1070000043000001' => 'me_iso_spu_module.self',
'1070000044000001' => '(related to usb dongle)',
'1070000045000001' => '(related to usb dongle)',
'1070000046000001' => 'spu_mode_auth.self', 
'107000004C000001' => 'spu_utoken_processor.self',
'107000004F000001' => 'unknown',
'1070000050000001' => 'unknown',
'1070000052000001' => 'sys',
'1070000054000001' => 'unknown',
'1070000055000001' => 'manu_info_spu_module.self', 
'1070000056000001' => 'cachemgr.self',
'1070000057000001' => 'EBOOT.BIN.self + .sprx files',
'1070000058000001' => 'me_iso_for_ps2emu.self',	
'1070000059000001' => 'sv_iso_for_ps2emu.self',
'10700003FC000001' => 'emer_init.self', 
'10700003FD000001' => 'ps3swu',
'1070000409000001' => 'pspemu', 
'107000040A000001' => 'psp translator',
'107000040B000001' => 'psp modules', 
'107000040C000001' => 'psp emu drm',
'1070000501000001' => 'hdd_copy.self', 
'10700005FC000001' => 'sys_audio', 
'10700005FD000001' => 'sys_init_osd',
'10700005FF000001' => 'vsh.self',
'1FF0000001000001' => 'lv0',
'1FF0000002000001' => 'lv1.self',
'1FF0000008000001' => 'lv1ldr', 
'1FF0000009000001' => 'lv2ldr',
'1FF000000A000001' => 'isoldr',
'1FF000000C000001' => 'appldr', 
'1070000500000001' => 'cellftp', 
'10700003FE000001' => 'sys_agent.self',
'10700003FF000001' => 'db_backup, mkfs, mkfs_085, mount_hdd, registry_backup, set_monitor',
'1070000048000001' => 'ftpd', 
'10700003FD000001' => 'PS3ToolUpdater',
);

############################################################################################################################################
my @danger;
my @ok;
my @warning;

my $ok = "<font color=green> &#10004;</font><br>";
my $danger = "<b><font color=red>[DANGER]</font></b>";
my $warning = "<b><font color=#FF8000>[WARNING]</font></b>";

############################################################################################################################################
print "\nChecking First Region Header...\n\n"; 

seek($bin, 0x00, 0); read($bin, my $firstregion_blank, 0x10); $firstregion_blank = uc ascii_to_hex($firstregion_blank);
seek($bin, 0x14, 0); read($bin, my $faceoff, 0x04); $faceoff = uc ascii_to_hex($faceoff);
seek($bin, 0x1C, 0); read($bin, my $deadbeef, 0x04); $deadbeef = uc ascii_to_hex($deadbeef);
seek($bin, 0x27, 0); read($bin, my $firstregion_count, 0x01); $firstregion_count = uc ascii_to_hex($firstregion_count);
seek($bin, 0x2F, 0); read($bin, my $firstregion_unknown, 0x01); $firstregion_unknown = uc ascii_to_hex($firstregion_unknown);
seek($bin, 0x30, 0); read($bin, my $firstregion_filledblock, 0x90); $firstregion_filledblock = uc ascii_to_hex($firstregion_filledblock);
print F "<div id=\"frgeneric\">";
print F "<br><b>First Region Header:</b><br>";

print F "Unknown Blank -"; if ($firstregion_blank eq "00000000000000000000000000000000") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $firstregion_blank<br>";}
print F "Magic Header - "; if ($faceoff eq "0FACE0FF" and $deadbeef eq "DEADBEEF") { print F "$faceoff - $deadbeef", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $faceoff $deadbeef<br>";}
print F "Region Count - "; if ($firstregion_count eq "00") { print F "$firstregion_count", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $firstregion_count<br>";}
print F "Unknown - "; if ($firstregion_unknown eq "00") { print F "$firstregion_unknown", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $firstregion_unknown<br>";}
print F "Blank Filled Block -"; if ($firstregion_filledblock =~ m!^[00]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}


############################################################################################################################################
print "\nChecking Flash Format...\n\n"; 

seek($bin, 0x200, 0); read($bin, my $ifi, 0x10); $ifi = uc ascii_to_hex($ifi);
seek($bin, 0x210, 0); read($bin, my $ififiller, 0x1F0); $ififiller = uc ascii_to_hex($ififiller);

print F "<br><b>Flash Format:</b><br>"; 

print F "Format/Version - "; if ($ifi eq "49464900000000010000000200000000") { print F "IFI '120'", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ifi<br>";}
print F "Filled Block -"; if ($ififiller =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - Too long to display!<br>";}

############################################################################################################################################better dynamic string handling than coreos :)
print "\nChecking Flash-Region Table...\n\n"; 

seek($bin, 0x407, 0); read($bin, my $flashregion_count, 0x01); $flashregion_count = uc ascii_to_hex($flashregion_count); my $flashregion_count_dec = hex($flashregion_count);
seek($bin, 0x40D, 0); read($bin, my $flashregion_length, 0x03); $flashregion_length = uc ascii_to_hex($flashregion_length);

seek($bin, 0x420, 0);read($bin, my $asecure_loader ,0x10); $asecure_loader = unpack('H*', "$asecure_loader"); $asecure_loader =~ s{00}{}g; $asecure_loader = pack('H*', "$asecure_loader");
seek($bin, 0x415, 0);read($bin, my $asecure_loader_loc ,0x03); $asecure_loader_loc = uc ascii_to_hex($asecure_loader_loc);
seek($bin, 0x41D, 0);read($bin, my $asecure_loader_size ,0x03); $asecure_loader_size = uc ascii_to_hex($asecure_loader_size);
my $asecure_loader_rloc = hex($asecure_loader_loc); $asecure_loader_rloc = ($asecure_loader_rloc + 1024); $asecure_loader_rloc = uc sprintf("%x", $asecure_loader_rloc);

seek($bin, 0x450, 0);read($bin, my $eeid,0x10); $eeid = unpack('H*', "$eeid"); $eeid =~ s{00}{}g; $eeid = pack('H*', "$eeid");
seek($bin, 0x445, 0);read($bin, my $eeid_loc,0x03); $eeid_loc = uc ascii_to_hex($eeid_loc);
seek($bin, 0x44D, 0);read($bin, my $eeid_size,0x03); $eeid_size = uc ascii_to_hex($eeid_size);
my $eeid_rloc = hex($eeid_loc); $eeid_rloc = ($eeid_rloc + 1024); $eeid_rloc = uc sprintf("%x", $eeid_rloc);

seek($bin, 0x480, 0);read($bin, my $cisd,0x10); $cisd = unpack('H*', "$cisd"); $cisd =~ s{00}{}g; $cisd = pack('H*', "$cisd");
seek($bin, 0x475, 0);read($bin, my $cisd_loc,0x03); $cisd_loc = uc ascii_to_hex($cisd_loc);
seek($bin, 0x47D, 0);read($bin, my $cisd_size,0x03); $cisd_size = uc ascii_to_hex($cisd_size);
my $cisd_rloc = hex($cisd_loc); $cisd_rloc = ($cisd_rloc + 1024); $cisd_rloc = uc sprintf("%x", $cisd_rloc);

seek($bin, 0x4B0, 0);read($bin, my $ccsd,0x10); $ccsd = unpack('H*', "$ccsd"); $ccsd =~ s{00}{}g; $ccsd = pack('H*', "$ccsd");
seek($bin, 0x4A5, 0);read($bin, my $ccsd_loc,0x03); $ccsd_loc = uc ascii_to_hex($ccsd_loc);
seek($bin, 0x4AD, 0);read($bin, my $ccsd_size,0x03); $ccsd_size = uc ascii_to_hex($ccsd_size);
my $ccsd_rloc = hex($ccsd_loc); $ccsd_rloc = ($ccsd_rloc + 1024); $ccsd_rloc = uc sprintf("%x", $ccsd_rloc);

seek($bin, 0x4E0, 0);read($bin, my $trvk_prg0,0x10); $trvk_prg0 = unpack('H*', "$trvk_prg0"); $trvk_prg0 =~ s{00}{}g; $trvk_prg0 = pack('H*', "$trvk_prg0");
seek($bin, 0x4D5, 0);read($bin, my $trvk_prg0_loc,0x03); $trvk_prg0_loc = uc ascii_to_hex($trvk_prg0_loc);
seek($bin, 0x4DD, 0);read($bin, my $trvk_prg0_size,0x03); $trvk_prg0_size = uc ascii_to_hex($trvk_prg0_size);
my $trvk_prg0_rloc = hex($trvk_prg0_loc); $trvk_prg0_rloc = ($trvk_prg0_rloc + 1024); $trvk_prg0_rloc = uc sprintf("%x", $trvk_prg0_rloc);

seek($bin, 0x510, 0);read($bin, my $trvk_prg1,0x10); $trvk_prg1 = unpack('H*', "$trvk_prg1"); $trvk_prg1 =~ s{00}{}g; $trvk_prg1 = pack('H*', "$trvk_prg1");
seek($bin, 0x505, 0);read($bin, my $trvk_prg1_loc,0x03); $trvk_prg1_loc = uc ascii_to_hex($trvk_prg1_loc);
seek($bin, 0x50D, 0);read($bin, my $trvk_prg1_size,0x03); $trvk_prg1_size = uc ascii_to_hex($trvk_prg1_size);
my $trvk_prg1_rloc = hex($trvk_prg1_loc); $trvk_prg1_rloc = ($trvk_prg1_rloc + 1024); $trvk_prg1_rloc = uc sprintf("%x", $trvk_prg1_rloc);

seek($bin, 0x540, 0);read($bin, my $trvk_pkg0,0x10); $trvk_pkg0 = unpack('H*', "$trvk_pkg0"); $trvk_pkg0 =~ s{00}{}g; $trvk_pkg0 = pack('H*', "$trvk_pkg0");
seek($bin, 0x535, 0);read($bin, my $trvk_pkg0_loc,0x03); $trvk_pkg0_loc = uc ascii_to_hex($trvk_pkg0_loc);
seek($bin, 0x53D, 0);read($bin, my $trvk_pkg0_size,0x03); $trvk_pkg0_size = uc ascii_to_hex($trvk_pkg0_size);
my $trvk_pkg0_rloc = hex($trvk_pkg0_loc); $trvk_pkg0_rloc = ($trvk_pkg0_rloc + 1024); $trvk_pkg0_rloc = uc sprintf("%x", $trvk_pkg0_rloc);

seek($bin, 0x570, 0);read($bin, my $trvk_pkg1,0x10); $trvk_pkg1 = unpack('H*', "$trvk_pkg1"); $trvk_pkg1 =~ s{00}{}g; $trvk_pkg1 = pack('H*', "$trvk_pkg1");
seek($bin, 0x565, 0);read($bin, my $trvk_pkg1_loc,0x03); $trvk_pkg1_loc = uc ascii_to_hex($trvk_pkg1_loc);
seek($bin, 0x56D, 0);read($bin, my $trvk_pkg1_size,0x03); $trvk_pkg1_size = uc ascii_to_hex($trvk_pkg1_size);
my $trvk_pkg1_rloc = hex($trvk_pkg1_loc); $trvk_pkg1_rloc = ($trvk_pkg1_rloc + 1024); $trvk_pkg1_rloc = uc sprintf("%x", $trvk_pkg1_rloc);

seek($bin, 0x5A0, 0);read($bin, my $ros0,0x10); $ros0 = unpack('H*', "$ros0"); $ros0 =~ s{00}{}g; $ros0 = pack('H*', "$ros0");
seek($bin, 0x595, 0);read($bin, my $ros0_loc,0x03); $ros0_loc = uc ascii_to_hex($ros0_loc);
seek($bin, 0x59D, 0);read($bin, my $ros0_size,0x03); $ros0_size = uc ascii_to_hex($ros0_size);
my $ros0_rloc = hex($ros0_loc); $ros0_rloc = ($ros0_rloc + 1024); $ros0_rloc = uc sprintf("%x", $ros0_rloc);

seek($bin, 0x5D0, 0);read($bin, my $ros1,0x10); $ros1 = unpack('H*', "$ros1"); $ros1 =~ s{00}{}g; $ros1 = pack('H*', "$ros1");
seek($bin, 0x5C5, 0);read($bin, my $ros1_loc,0x03); $ros1_loc = uc ascii_to_hex($ros1_loc); 
seek($bin, 0x5CD, 0);read($bin, my $ros1_size,0x03); $ros1_size = uc ascii_to_hex($ros1_size);
my $ros1_rloc = hex($ros1_loc); $ros1_rloc = ($ros1_rloc + 1024); $ros1_rloc = uc sprintf("%x", $ros1_rloc);

seek($bin, 0x600, 0);read($bin, my $cvtrm,0x10); $cvtrm = unpack('H*', "$cvtrm"); $cvtrm =~ s{00}{}g; $cvtrm = pack('H*', "$cvtrm");
seek($bin, 0x5F5, 0);read($bin, my $cvtrm_loc,0x03); $cvtrm_loc = uc ascii_to_hex($cvtrm_loc);
seek($bin, 0x5FD, 0);read($bin, my $cvtrm_size,0x03); $cvtrm_size = uc ascii_to_hex($cvtrm_size);
my $cvtrm_rloc = hex($cvtrm_loc); $cvtrm_rloc = ($cvtrm_rloc + 1024); $cvtrm_rloc = uc sprintf("%x", $cvtrm_rloc);

#my %filetable = map { $_ => 1 } ("asecure_loader","eEID","cISD","cCSD","trvk_prg0","trvk_prg1","trvk_pkg0","trvk_pkg1","ros0","ros1","cvtrm");

print F "<div id=\"frperconsole\"></div>";
print F "<div style = \"text-align:right; float:right\"><a href=\"#Top\">Return</a></div><br>";
print F "<br><b>Flash-Region Table:</b><br>";

print F "Count - "; if ($flashregion_count_dec eq "11") { print F "$flashregion_count_dec", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $flashregion_count_dec<br>";}
print F "Length - "; if ($flashregion_length eq "EFFC00") { print F "$flashregion_length", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $flashregion_length<br><br>";}

if ($asecure_loader eq "asecure_loader") {print F $asecure_loader, $ok; push(@ok, "OK")} else {push(@danger, "Danger"); print F "$danger - $asecure_loader<br>";} if ($asecure_loader_size eq "02E800") {print F "Size: $asecure_loader_size", $ok; push(@ok, "OK")} else {print F "Size: $danger - $asecure_loader_size<br>";} if ($asecure_loader_loc eq "000400") {print F "Location: $asecure_loader_loc (0x$asecure_loader_rloc)", $ok; push(@ok, "OK"); print F "<br>"} else {print F "Location: $danger - $asecure_loader_loc<br><br>";} 
if ($eeid eq "eEID") {print F $eeid, $ok; push(@ok, "OK")} else {push(@danger, "Danger"); print F "$danger - $eeid<br>";} if ($eeid_size eq "010000") {print F "Size: $eeid_size", $ok; push(@ok, "OK")} else {print F "Size: $danger - $eeid_size<br>";} if ($eeid_loc eq "02EC00") {print F "Location: $eeid_loc (0x$eeid_rloc)", $ok; push(@ok, "OK"); print F "<br>"} else {print F "Location: $danger - $eeid_loc<br><br>";}  
if ($cisd eq "cISD") {print F $cisd, $ok; push(@ok, "OK")} else {push(@danger, "Danger"); print F "$danger - $cisd<br>";} if ($cisd_size eq "000800") {print F "Size: $cisd_size", $ok; push(@ok, "OK")} else {print F "Size: $danger - $cisd_size<br>";} if ($cisd_loc eq "03EC00") {print F "Location: $cisd_loc (0x$cisd_rloc)", $ok; push(@ok, "OK"); print F "<br>"} else {print F "Location: $danger - $cisd_loc<br><br>";} 
if ($ccsd eq "cCSD") {print F $ccsd, $ok; push(@ok, "OK")} else {push(@danger, "Danger"); print F "$danger - $ccsd<br>";} if ($ccsd_size eq "000800") {print F "Size: $ccsd_size", $ok; push(@ok, "OK")} else {print F "Size: $danger - $ccsd_size<br>";} if ($ccsd_loc eq "03F400") {print F "Location: $ccsd_loc (0x$ccsd_rloc)", $ok; push(@ok, "OK"); print F "<br>"} else {print F "Location: $danger - $ccsd_loc<br><br>";} 
if ($trvk_prg0 eq "trvk_prg0") {print F $trvk_prg0, $ok; push(@ok, "OK")} else {push(@danger, "Danger"); print F "$danger - $trvk_prg0<br>";} if ($trvk_prg0_size eq "020000") {print F "Size: $trvk_prg0_size", $ok; push(@ok, "OK")} else {print F "Size: $danger - $trvk_prg0_size<br>";} if ($trvk_prg0_loc eq "03FC00") {print F "Location: $trvk_prg0_loc (0x$trvk_prg0_rloc)", $ok; push(@ok, "OK"); print F "<br>"} else {print F "Location: $danger - $trvk_prg0_loc<br><br>";} 
if ($trvk_prg1 eq "trvk_prg1") {print F $trvk_prg1, $ok; push(@ok, "OK")} else {push(@danger, "Danger"); print F "$danger - $trvk_prg1<br>";} if ($trvk_prg1_size eq "020000") {print F "Size: $trvk_prg1_size", $ok; push(@ok, "OK")} else {print F "Size: $danger - $trvk_prg1_size<br>";} if ($trvk_prg1_loc eq "05FC00") {print F "Location: $trvk_prg1_loc (0x$trvk_prg1_rloc)", $ok; push(@ok, "OK"); print F "<br>"} else {print F "Location: $danger - $trvk_prg1_loc<br><br>";} 
if ($trvk_pkg0 eq "trvk_pkg0") {print F $trvk_pkg0, $ok; push(@ok, "OK")} else {push(@danger, "Danger"); print F "$danger - $trvk_pkg0<br>";} if ($trvk_pkg0_size eq "020000") {print F "Size: $trvk_pkg0_size", $ok; push(@ok, "OK")} else {print F "Size: $danger - $trvk_pkg0_size<br>";} if ($trvk_pkg0_loc eq "07FC00") {print F "Location: $trvk_pkg0_loc (0x$trvk_pkg0_rloc)", $ok; push(@ok, "OK"); print F "<br>"} else {print F "Location: $danger - $trvk_pkg0_loc<br><br>";} 
if ($trvk_pkg1 eq "trvk_pkg1") {print F $trvk_pkg1, $ok; push(@ok, "OK")} else {push(@danger, "Danger"); print F "$danger - $trvk_pkg1<br>";} if ($trvk_pkg1_size eq "020000") {print F "Size: $trvk_pkg1_size", $ok; push(@ok, "OK")} else {print F "Size: $danger - $trvk_pkg1_size<br>";} if ($trvk_pkg1_loc eq "09FC00") {print F "Location: $trvk_pkg1_loc (0x$trvk_pkg1_rloc)", $ok; push(@ok, "OK"); print F "<br>"} else {print F "Location: $danger - $trvk_pkg1_loc<br><br>";} 
if ($ros0 eq "ros0") {print F $ros0, $ok; push(@ok, "OK")} else {push(@danger, "Danger"); print F "$danger - $ros0<br>";} if ($ros0_size eq "700000") {print F "Size: $ros0_size", $ok; push(@ok, "OK")} else {print F "Size: $danger - $ros0_size<br>";} if ($ros0_loc eq "0BFC00") {print F "Location: $ros0_loc (0x$ros0_rloc)", $ok; push(@ok, "OK"); print F "<br>"} else {print F "Location: $danger - $ros0_loc<br><br>";} 
if ($ros1 eq "ros1") {print F $ros1, $ok; push(@ok, "OK")} else {push(@danger, "Danger"); print F "$danger - $ros1<br>";} if ($ros1_size eq "700000") {print F "Size: $ros1_size", $ok; push(@ok, "OK")} else {print F "Size: $danger - $ros1_size<br>";} if ($ros1_loc eq "7BFC00") {print F "Location: $ros1_loc (0x$ros1_rloc)", $ok; push(@ok, "OK"); print F "<br>"} else {print F "Location: $danger - $ros1_loc<br><br>";} 
if ($cvtrm eq "cvtrm") {print F $cvtrm, $ok; push(@ok, "OK")} else {push(@danger, "Danger"); print F "$danger - $cvtrm<br>";} if ($cvtrm_size eq "040000") {print F "Size: $cvtrm_size", $ok; push(@ok, "OK")} else {print F "Size: $danger - $cvtrm_size<br>";} if ($cvtrm_loc eq "EBFC00") {print F "Location: $cvtrm_loc (0x$cvtrm_rloc)", $ok; push(@ok, "OK"); print F "<br>"} else {print F "Location: $danger - $cvtrm_loc<br><br>";} 


my $ra = Regexp::Assemble->new;
$ra->add( '([^ÿ]ÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿ[^ÿ])' );
$ra->add( '([^ÿ]ÿÿÿÿÿÿÿÿ[^ÿ])' );
$ra->add( '([^ÿ]ÿ{2,}[^ÿ])' );
$ra->add( '(ÿ{2,})' );
$ra->add( '(ÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿ)' );
$ra->add( '(ÿÿÿÿÿÿÿÿ)' );
my $regex = $ra->re; my @matches_fr;
seek($bin, 0x400, 0);read($bin, my $match_fr, 0x400);
#$match = uc ascii_to_hex($match); 
while ($match_fr =~ m/($regex)/g){
    my $match_fr = $1;
    my $offset = $-[0] + 0x400;
	$offset = uc sprintf("%x",$offset);
    push @matches_fr, "[$match_fr] found at offset: 0x$offset ";
}
print F "Structure/Corruption Check - "; 
if (grep {defined($_)} @matches_fr) {push(@danger, "Danger"); print F "$danger"; push(@danger, "DANGER");} else {print F $ok; push(@ok, "OK");}


############################################################################################################################################ 
print "\nChecking Asecure_Loader/Metldr...\n\n"; 

seek($bin, 0x81E, 0); read($bin, my $metldr_filelength, 0x02); $metldr_filelength = uc ascii_to_hex($metldr_filelength);
seek($bin, 0x842, 0); read($bin, my $metldr_binarysize, 0x02); $metldr_binarysize = uc ascii_to_hex($metldr_binarysize);
seek($bin, 0x852, 0); read($bin, my $metldr_binarysize2, 0x02); $metldr_binarysize2 = uc ascii_to_hex($metldr_binarysize2);
seek($bin, 0x820, 0); read($bin, my $metldr_string, 0x08);
seek($bin, 0x844, 0); read($bin, my $metldr_revision_key, 0x0C); $metldr_revision_key = uc ascii_to_hex($metldr_revision_key);
seek($bin, 0x854, 0);read($bin, my $metldr_pcn ,0x0C); $metldr_pcn = uc ascii_to_hex($metldr_pcn);

print F "<br><b>Asecure_Loader/Metldr:</b><br>"; 

my $metldr_filelength_result = $metldr_filelength_list{$metldr_filelength};
my $metldr_binarysize_result = $metldr_filelength_list{$metldr_binarysize};
my $metldr_filelength_dec = hex($metldr_binarysize); my $metldr_filelength_calc = ($metldr_filelength_dec * 16 + 64);
my $metldr_filelength_calc_convert = uc sprintf("%x", $metldr_filelength_calc);


my $metldr_emptyspace = 2112 + hex($metldr_filelength_calc_convert); #metldr start plus metldr size = metldr end
my $metldr_emptyspace_length = 192512 - $metldr_emptyspace; #eid start minus metldr end
seek ($bin, $metldr_emptyspace,0); read ($bin, my $metldr_emptyspaces, $metldr_emptyspace_length);

print F "File Length - "; if (exists $metldr_filelength_list{$metldr_filelength}) { my $metldr_filelength_result = $metldr_filelength_list{$metldr_filelength}; print F "$metldr_filelength_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $metldr_filelength<br>";}
print F "Encrypted Binary Size - "; if (exists $metldr_binarysize_list{$metldr_binarysize}){ my $metldr_binarysize_result = $metldr_binarysize_list{$metldr_binarysize}; print F "$metldr_binarysize_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $metldr_binarysize<br>";}
print F "Decrypted Binary Size - "; if ($metldr_binarysize2 eq $metldr_binarysize) { print F "$metldr_binarysize2", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $metldr_binarysize2<br>";}
print F "File Name - "; if ($metldr_string eq "metldr  " or "metldr.2") { print F "$metldr_string", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $metldr_string<br>";}
print F "Calculated Metldr Size - "; if ($metldr_filelength eq $metldr_filelength_calc_convert) { ; print F "$metldr_filelength_calc_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $metldr_filelength / $metldr_filelength_calc_convert<br>";}
print F "Rev Key - "; if (exists $metldr_revision_key_list{$metldr_revision_key}) { my $metldr_revision_key_result = $metldr_revision_key_list{$metldr_revision_key}; print F "$metldr_revision_key ($metldr_revision_key_result)", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $metldr_revision_key<br>";}
print F "PerConsole Nonce - "; if ($metldr_pcn =~ m![^00|FF]*$!) { print F "$metldr_pcn", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $metldr_pcn<br>";}
print F "Metldr Version - "; 
if ($metldr_revision_key eq "C3266E4BBB282E76B7677095") {print F "Metldr Old (3.50+ Enforced)", $ok; push(@ok, "OK")} 
if ($metldr_revision_key eq "DBA53B0AB5181D971524615B") {print F "Metldr.2 (3.56+ Enforced)", $ok; push(@ok, "OK")} 
elsif ($metldr_revision_key eq "A2834B1DFD969CC1769517C6") {push(@warning, "WARNING"); print F "$warning - Metldr.2 - Not downgradeable!<br>";} 
elsif ($metldr_revision_key eq "C36C2E4300AACBE6F64FAD92") {push(@warning, "WARNING"); print F "$warning - Metldr.2 - Not downgradeable!<br>";} 
elsif ($metldr_revision_key eq "39ECF2D2ACC0E0752248A9F8") {push(@warning, "WARNING"); print F "$warning - Metldr.2 - Not downgradeable!<br>";} 
elsif ($metldr_revision_key eq "EA838371878EF0892A5EF6B6") {push(@warning, "WARNING"); print F "$warning - Metldr.2 - Not downgradeable!<br>";} 
else { print F "Metldr Old - Downgradeable", $ok; push(@ok, "OK")}

$ra->add( '([^ÿ]ÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿ[^ÿ])' );
$ra->add( '([^ÿ]ÿÿÿÿÿÿÿÿ[^ÿ])' );
$ra->add( '([^ÿ]ÿ{3,}[^ÿ])' );
$ra->add( '(ÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿ)' );
$ra->add( '(ÿÿÿÿÿÿÿÿ)' );
$regex = $ra->re; my @matches_es;
seek($bin, $metldr_emptyspace, 0);read($bin, my $match_es, $metldr_emptyspace_length);
local $/; use bytes; #$match = uc ascii_to_hex($match); 
while ($match_es =~ m/($regex)/g){
    my $match_es = $1;
    my $offset = $-[0] + $metldr_emptyspace;
	$offset = uc sprintf("%x",$offset);
    push @matches_es, "[$match_es] found at offset: 0x$offset ";
}
print F "Blank Filled Block - "; 
if (grep {defined($_)} @matches_es) {push(@warning, "WARNING"); print F "$warning<br>"; push(@warning, "WARNING")} else {print F $ok; push(@ok, "OK");}

print "\nChecking for Asecure_Loader/Metldr Corrupt Sequences...\n\n"; 

$ra->add( '([^ÿ]ÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿ[^ÿ])' );
$ra->add( '([^ÿ]ÿÿÿÿÿÿÿÿ[^ÿ])' );
$ra->add( '([^ÿ]ÿ{3,}[^ÿ])' );
$ra->add( '(ÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿ)' );
$ra->add( '(ÿÿÿÿÿÿÿÿ)' );
$ra->add( '([^\0]\0{8}[^\0])' );
$ra->add( '([^\0]\0{16}[^\0])' );
$ra->add( '([^\0|@|r]\0{3,}[^\0])' );
$regex = $ra->re; my @matches;
seek($bin, 0x830, 0);read($bin, my $match, $metldr_filelength_dec); #ITS 830 instead of 810 because i cant be fucked solving the metldr.2 problem
local $/; use bytes; #$match = uc ascii_to_hex($match); 
while ($match =~ m/($regex)/g){
    my $match = $1;
    my $offset = $-[0] + 0x830;
	$offset = uc sprintf("%x",$offset);
    push @matches, "[$match] found at offset: 0x$offset";
}
print F "<br><b>Asecure_Loader/Metldr Corrupt Sequence Check:</b><br>"; 
@matches = grep {$_ ne "[2] found at offset: 0x827"} @matches;
if (grep {defined($_)} @matches) {print F "$_ - $danger"; push(@danger, "DANGER") foreach @matches;} else {print F "Nothing Found! $ok"; push(@ok, "OK");}

############################################################################################################################################
print "\nCalculating Asecure_Loader/Metldr Encrypted Statistics...\n\n"; 

print F "<br><b>Asecure_Loader/Metldr Encrypted Statistics:</b><br>"; 
my %metldr_stats;

if (exists $metldr_filelength_list{$metldr_filelength}) {seek($bin, 0x840, 0); read($bin, my $metldr_stats_range, $metldr_filelength_calc);while () {$metldr_stats{sprintf "%02X", ord $_}++ for split//, $metldr_stats_range; last;}}

my @list = values %metldr_stats;
use Statistics::Lite qw(:all);
my $sum1 = sum @list;
my $mean1 = mean @list;
my $stddev1 = stddev @list;
my %list = statshash @list;
#print F statsinfo(@list);

print F "Sum: "; if ($sum1 < 59310) { print F "$sum1 - $danger"; push(@danger, "DANGER");} elsif ($sum1 > 63920) { print F "$sum1 - $danger"; push(@danger, "DANGER");} else { print F $sum1, $ok; push(@ok, "OK")}
#was 59520
print F "Mean: "; if ($mean1 < 231.65) { print F "$mean1 - $danger"; push(@danger, "DANGER");} elsif ($mean1 > 249.70) { print F "$mean1 - $danger"; push(@danger, "DANGER");} else { print F $mean1, $ok; push(@ok, "OK")}
#was 232.50
print F "Std Dev: "; if ($stddev1 < 13.450) { print F "$stddev1 - $warning [Unsafe below 13]<br>"; push(@warning, "WARNING")} elsif ($stddev1 > 17.059) { print F "$stddev1 - $warning [Unsafe above 17.5]<br>"; push(@warning, "WARNING")} else { print F $stddev1, $ok; push(@ok, "OK")}
#was 16.150

###################

seek($bin, 0x840, 0); read($bin, my $metldr_stats_range2, $metldr_filelength_calc);

my %Count;    
my $total = 0; 
                     
    foreach my $char (split(//, $metldr_stats_range2)) { 
        $Count{$char}++;               
        $total++;                    
    }

my $metldr_entropy = 0;                        
foreach my $char (keys %Count) {    
    my $p = $Count{$char}/$total;  
    $metldr_entropy += $p * log($p);             
}
$metldr_entropy = -$metldr_entropy/log(2);                    

print F "Entropy: "; if ($metldr_entropy < 7.99) { print F "$metldr_entropy - $danger<br>"; push(@danger, "DANGER")} else { print F "$metldr_entropy Bits", $ok; push(@ok, "OK")}
       

############################################################################################################################################
print "\nChecking EID...\n\n"; 

seek($bin, 0x2F003, 0);read($bin, my $eid_count ,0x01); $eid_count = uc ascii_to_hex($eid_count);
seek($bin, 0x2F006, 0);read($bin, my $eid_length ,0x02); $eid_length = uc ascii_to_hex($eid_length);
seek($bin, 0x2F008, 0);read($bin, my $eid_filler ,0x08); $eid_filler = uc ascii_to_hex($eid_filler);

seek($bin, 0x2F010, 0);read($bin, my $eid_0e ,0x4); $eid_0e = uc ascii_to_hex($eid_0e);
seek($bin, 0x2F014, 0);read($bin, my $eid_0l ,0x4); $eid_0l = uc ascii_to_hex($eid_0l);
seek($bin, 0x2F018, 0);read($bin, my $eid_0 ,0x8); $eid_0 = uc ascii_to_hex($eid_0);

seek($bin, 0x2F020, 0);read($bin, my $eid_1e ,0x4); $eid_1e = uc ascii_to_hex($eid_1e);
seek($bin, 0x2F024, 0);read($bin, my $eid_1l ,0x4); $eid_1l = uc ascii_to_hex($eid_1l);
seek($bin, 0x2F028, 0);read($bin, my $eid_1 ,0x8); $eid_1 = uc ascii_to_hex($eid_1);

seek($bin, 0x2F030, 0);read($bin, my $eid_2e ,0x4); $eid_2e = uc ascii_to_hex($eid_2e);
seek($bin, 0x2F034, 0);read($bin, my $eid_2l ,0x4); $eid_2l = uc ascii_to_hex($eid_2l);
seek($bin, 0x2F038, 0);read($bin, my $eid_2 ,0x8); $eid_2 = uc ascii_to_hex($eid_2);

seek($bin, 0x2F040, 0);read($bin, my $eid_3e ,0x4); $eid_3e = uc ascii_to_hex($eid_3e);
seek($bin, 0x2F044, 0);read($bin, my $eid_3l ,0x4); $eid_3l = uc ascii_to_hex($eid_3l);
seek($bin, 0x2F048, 0);read($bin, my $eid_3 ,0x8); $eid_3 = uc ascii_to_hex($eid_3);

seek($bin, 0x2F050, 0);read($bin, my $eid_4e ,0x4); $eid_4e = uc ascii_to_hex($eid_4e);
seek($bin, 0x2F054, 0);read($bin, my $eid_4l ,0x4); $eid_4l = uc ascii_to_hex($eid_4l);
seek($bin, 0x2F058, 0);read($bin, my $eid_4 ,0x8); $eid_4 = uc ascii_to_hex($eid_4);

seek($bin, 0x2F060, 0);read($bin, my $eid_5e ,0x4); $eid_5e = uc ascii_to_hex($eid_5e);
seek($bin, 0x2F064, 0);read($bin, my $eid_5l ,0x4); $eid_5l = uc ascii_to_hex($eid_5l);
seek($bin, 0x2F068, 0);read($bin, my $eid_5 ,0x8); $eid_5 = uc ascii_to_hex($eid_5);

print F "<br><b>Encrypted Individual Data:</b><br>"; 

print F "Entries - "; if ($eid_count eq "06") { print F "$eid_count", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_count<br>";}
print F "eEID Package Length - "; if ($eid_length eq "1DD0") { print F "$eid_length", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_length<br>";}
print F "Blank Filler - "; if ($eid_filler eq "0000000000000000") { print F $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_filler<br>";}

print F "<br><b>EID Entry Table:</b><br>";

print F "EID0<br>";
print F "Entry Point - "; if ($eid_0e eq "00000070") { print F "0070", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_0e<br>";}
print F "Length - "; if ($eid_0l eq "00000860") { print F "0860", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_0l<br>";}
print F "EID Number - "; if ($eid_0 eq "0000000000000000") { print F "0", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_0<br>";}

print F "<br>EID1<br>";
print F "Entry Point - "; if ($eid_1e eq "000008D0") { print F "08D0", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_1e<br>";}
print F "Length - "; if ($eid_1l eq "000002A0") { print F "02A0", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_1l<br>";}
print F "EID Number - "; if ($eid_1 eq "0000000000000001") { print F "1", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_1<br>";}

print F "<br>EID2<br>";
print F "Entry Point - "; if ($eid_2e eq "00000B70") { print F "0B70", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_2e<br>";}
print F "Length - "; if ($eid_2l eq "00000730") { print F "0730", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_2l<br>";}
print F "EID Number - "; if ($eid_2 eq "0000000000000002") { print F "2", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_2<br>";}

print F "<br>EID3<br>";
print F "Entry Point - "; if ($eid_3e eq "000012A0") { print F "12A0", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_3e<br>";}
print F "Length - "; if ($eid_3l eq "00000100") { print F "0100", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_3l<br>";}
print F "EID Number - "; if ($eid_3 eq "0000000000000003") { print F "3", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_3<br>";}

print F "<br>EID4<br>";
print F "Entry Point - "; if ($eid_4e eq "000013A0") { print F "13A0", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_4e<br>";}
print F "Length - "; if ($eid_4l eq "00000030") { print F "0030", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_4l<br>";}
print F "EID Number - "; if ($eid_4 eq "0000000000000004") { print F "4", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_4<br>";}

print F "<br>EID5<br>";
print F "Entry Point - "; if ($eid_5e eq "000013D0") { print F "13D0", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_5e<br>";}
print F "Length - "; if ($eid_5l eq "00000A00") { print F "0A00", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_5l<br>";}
print F "EID Number - "; if ($eid_5 eq "0000000000000005") { print F "5", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid_5<br>";}

############################################################################################################################################
print "\nChecking EID0...\n\n"; 

seek($bin, 0x2F084, 0);read($bin, my $pcn_eid ,0x0C);
seek($bin, 0x2F080, 0);read($bin, my $eid0_count, 0x04);
seek($bin, 0x2F070, 0);read($bin, my $eid0_idps, 0x10);
seek($bin, 0x303D0, 0);read($bin, my $eid5_idps, 0x10);

print F "<br><b>EID0:</b><br>";

my $eid0_idps_convert = uc ascii_to_hex($eid0_idps);
my $pcn_eid_convert = uc ascii_to_hex($pcn_eid);
my $eid0_count_convert = uc ascii_to_hex($eid0_count);

print F "IDPS - "; if ($eid5_idps eq $eid0_idps) { print F "$eid0_idps_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid0_idps_convert<br>";}
print F "PerConsole Nonce - "; if ($pcn_eid_convert =~ m![^00|FF]*$!) { print F "$pcn_eid_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $pcn_eid_convert<br>";}
print F "Static + Count - "; if ($eid0_count_convert eq "0012000B") { print F "$eid0_count_convert (11)", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid0_count_convert<br>";}

seek($bin, 0x2F090, 0); read($bin, my $eid0_range, 0x840);
my %Count; my $total = 0; my $eid0_entropy = 0; 
foreach my $char (split(//, $eid0_range)) {$Count{$char}++; $total++;}
foreach my $char (keys %Count) {my $p = $Count{$char}/$total; $eid0_entropy += $p * log($p);}
$eid0_entropy = -$eid0_entropy/log(2);                    

print F "EID Data Entropy: "; if ($eid0_entropy < 6.00) { print F "$eid0_entropy - $warning<br>"; push(@warning, "WARNING")} else { print F "$eid0_entropy Bits", $ok; push(@ok, "OK")}

############################################################################################################################################
print "\nChecking EID1...\n\n"; 

print F "<br><b>EID1:</b><br>";

seek($bin, 0x2F8D0, 0); read($bin, my $eid1_range, 0x2A0);
my %Count; my $total = 0; my $eid1_entropy = 0; 
foreach my $char (split(//, $eid1_range)) {$Count{$char}++; $total++;}
foreach my $char (keys %Count) {my $p = $Count{$char}/$total; $eid1_entropy += $p * log($p);}
$eid1_entropy = -$eid1_entropy/log(2);                    

print F "EID Data Entropy: "; if ($eid1_entropy < 6.00) { print F "$eid1_entropy - $warning<br>"; push(@warning, "WARNING")} else { print F "$eid1_entropy Bits", $ok; push(@ok, "OK")}


############################################################################################################################################
print "\nChecking EID2...\n\n"; 

seek($bin, 0x2FB70, 0);read($bin, my $eid2_pblock, 0x02);
seek($bin, 0x2FB72, 0);read($bin, my $eid2_sblock, 0x02);
seek($bin, 0x2FB80, 0);read($bin, my $eid2_padding, 0x10);

print F "<br><b>EID2:</b><br>";

my $eid2_pblock_convert = uc ascii_to_hex($eid2_pblock);
my $eid2_sblock_convert = uc ascii_to_hex($eid2_sblock);
my $eid2_padding_convert = uc ascii_to_hex($eid2_padding);

print F "P-Block Size - "; if ($eid2_pblock_convert eq "0080") { print F "$eid2_pblock_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid2_pblock_convert<br>";}
print F "S-Block Size - "; if ($eid2_sblock_convert eq "0690") { print F "$eid2_sblock_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid2_sblock_convert<br>";}
print F "Padding"; if ($eid2_padding_convert eq "00000000000000000000000000000000") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $eid0_count_convert<br>";}

seek($bin, 0x2FB90, 0); read($bin, my $eid2_range, 0x710);
my %Count; my $total = 0; my $eid2_entropy = 0; 
foreach my $char (split(//, $eid2_range)) {$Count{$char}++; $total++;}
foreach my $char (keys %Count) {my $p = $Count{$char}/$total; $eid2_entropy += $p * log($p);}
$eid2_entropy = -$eid2_entropy/log(2);                    

print F "EID Data Entropy: "; if ($eid2_entropy < 6.00) { print F "$eid2_entropy - $warning<br>"; push(@warning, "WARNING")} else { print F "$eid2_entropy Bits", $ok; push(@ok, "OK")}

############################################################################################################################################
print "\nChecking EID3...\n\n"; 

seek($bin, 0x302A0, 0);read($bin, my $eid3_unknown1, 0x04); my $eid3_unknown1_convert = uc ascii_to_hex($eid3_unknown1);
seek($bin, 0x302B0, 0);read($bin, my $eid3_unknown2, 0x04); my $eid3_unknown2_convert = uc ascii_to_hex($eid3_unknown2);
seek($bin, 0x302B4, 0);read($bin, my $pcn_eid3 ,0x0C); my $pcn_eid3_convert = uc ascii_to_hex($pcn_eid3);

seek($bin, 0x302A4, 0);read($bin, my $eid3_indicatingid, 0x04); $eid3_indicatingid = uc ascii_to_hex($eid3_indicatingid);
seek($bin, 0x302A8, 0);read($bin, my $eid3_ckpmid, 0x08); $eid3_ckpmid = uc ascii_to_hex($eid3_ckpmid);

print F "<br><b>EID3:</b><br>";

print F "Content Availiability - "; if ($eid3_unknown1_convert eq "00000001") { print F "$eid3_unknown1_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid3_unknown1_convert<br>";}
print F "Indicating/Build ID - "; if ($eid3_indicatingid =~ m![^00|FF]*$!) { print F "$eid3_indicatingid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid3_indicatingid<br>";}
print F "CKP_Management_ID - "; if ($eid3_ckpmid =~ m![^00|FF]*$!) { print F "$eid3_ckpmid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid3_ckpmid<br>";}
print F "PerConsole Nonce - "; if ($pcn_eid3 =~ m![^00|FF]*$!) { print F "$pcn_eid3_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $pcn_eid3_convert<br>";}
print F "Unknown Static - "; if ($eid3_unknown2_convert eq "000100D0") { print F "$eid3_unknown2_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid3_unknown2_convert<br>";}

seek($bin, 0x302C0, 0); read($bin, my $eid3_range, 0xE0);
my %Count; my $total = 0; my $eid3_entropy = 0; 
foreach my $char (split(//, $eid3_range)) {$Count{$char}++; $total++;}
foreach my $char (keys %Count) {my $p = $Count{$char}/$total; $eid3_entropy += $p * log($p);}
$eid3_entropy = -$eid3_entropy/log(2);                    

print F "EID Data Entropy: "; if ($eid3_entropy < 6.00) { print F "$eid3_entropy - $warning<br>"; push(@warning, "WARNING")} else { print F "$eid3_entropy Bits", $ok; push(@ok, "OK")}

############################################################################################################################################
print "\nChecking EID4...\n\n"; 

print F "<br><b>EID4:</b><br>";

seek($bin, 0x303A0, 0);read($bin, my $eid4_128_1, 0x10); $eid4_128_1 = uc ascii_to_hex($eid4_128_1);
seek($bin, 0x303B0, 0);read($bin, my $eid4_128_2 ,0x10); $eid4_128_2 = uc ascii_to_hex($eid4_128_2);
seek($bin, 0x303C0, 0);read($bin, my $eid4_cmac ,0x10); $eid4_cmac = uc ascii_to_hex($eid4_cmac);

print F "128bit Key - "; if ($eid4_128_1 =~ m![^00|FF]*$!) { print F "$eid4_128_1", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid4_128_1<br>";}
print F "128bit Key  - "; if ($eid4_128_2 =~ m![^00|FF]*$!) { print F "$eid4_128_2", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid4_128_2<br>";}
print F "CMAC-OMAC1 - "; if ($eid4_cmac =~ m![^00|FF]*$!) { print F "$eid4_cmac", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid4_cmac<br>";}

seek($bin, 0x303A0, 0); read($bin, my $eid4_range, 0x30);
my %Count; my $total = 0; my $eid4_entropy = 0; 
foreach my $char (split(//, $eid4_range)) {$Count{$char}++; $total++;}
foreach my $char (keys %Count) {my $p = $Count{$char}/$total; $eid4_entropy += $p * log($p);}
$eid4_entropy = -$eid4_entropy/log(2);                    

print F "EID Data Entropy: "; if ($eid4_entropy < 5.00) { print F "$eid4_entropy - $warning<br>"; push(@warning, "WARNING")} else { print F "$eid4_entropy Bits", $ok; push(@ok, "OK")}

############################################################################################################################################
print "\nChecking EID5...\n\n"; 

seek($bin, 0x303E0, 0);read($bin, my $eid5_unknown, 0x04);
seek($bin, 0x303E4, 0);read($bin, my $pcn_eid5 ,0x0C);

print F "<br><b>EID5:</b><br>";

my $eid5_idps_convert = uc ascii_to_hex($eid5_idps);
my $pcn_eid5_convert = uc ascii_to_hex($pcn_eid5);
my $eid5_unknown_convert = uc ascii_to_hex($eid5_unknown);

print F "IDPS - "; if ($eid5_idps eq $eid0_idps) { print F "$eid5_idps_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid5_idps_convert<br>";}
print F "PerConsole Nonce - "; if ($pcn_eid5_convert =~ m![^00|FF]*$!) { print F "$pcn_eid5_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $pcn_eid5_convert<br>";}
print F "Unknown Static - "; if ($eid5_unknown_convert eq "00120730") { print F "$eid5_unknown_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid5_unknown_convert<br>";}

seek($bin, 0x303F0, 0); read($bin, my $eid5_range, 0x9E0);
my %Count; my $total = 0; my $eid5_entropy = 0; 
foreach my $char (split(//, $eid5_range)) {$Count{$char}++; $total++;}
foreach my $char (keys %Count) {my $p = $Count{$char}/$total; $eid5_entropy += $p * log($p);}
$eid5_entropy = -$eid5_entropy/log(2);                    

print F "EID Data Entropy: "; if ($eid5_entropy < 6.00) { print F "$eid5_entropy - $warning<br>"; push(@warning, "WARNING")} else { print F "$eid5_entropy Bits", $ok; push(@ok, "OK")}

############################################################################################################################################

seek($bin, 0x30DD0, 0);read($bin, my $eid_unrefa, 0xE230); $eid_unrefa = uc ascii_to_hex($eid_unrefa);

print F "<br><b>EID Unreferenced Area:</b><br>";

print F "Filled -"; if ($eid_unrefa =~ m!^[FF]*$!) {print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}


############################################################################################################################################
print "\nChecking IDPS...\n\n"; 

seek($bin, 0x2F075, 0);read($bin, my $target_id, 0x1);
seek($bin, 0x2F077, 0);read($bin, my $idps, 0x01);

print F "<br><b>IDPS Info:</b><br>";

my $target_id_convert = uc ascii_to_hex($target_id);
my $idps_convert = uc ascii_to_hex($idps);

print F "Target ID - "; if (exists $target_id_list{$target_id_convert}) { my $target_id_result = $target_id_list{$target_id_convert}; print F "$target_id_convert ($target_id_result)", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $target_id_convert<br>";}
print F "Model - "; if (exists $idps_list{$idps_convert}) { my $idps_result = $idps_list{$idps_convert}; print F "$idps_convert ($idps_result)", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $idps_convert<br>";}
print F "IDPS  - "; if ($eid5_idps eq $eid0_idps) { print F "EID0 & EID5", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $eid0_idps $eid5_idps<br>";}


#############################################################################################################################################
print "\nChecking CISD...\n\n"; 

seek($bin, 0x3F003, 0);read($bin, my $cisd_count ,0x01); $cisd_count = uc ascii_to_hex($cisd_count);
seek($bin, 0x3F006, 0);read($bin, my $cisd_length ,0x02); $cisd_length = uc ascii_to_hex($cisd_length);
seek($bin, 0x3F008, 0);read($bin, my $cisd_filler ,0x08); $cisd_filler = uc ascii_to_hex($cisd_filler);

seek($bin, 0x3F010, 0);read($bin, my $cisd_0e ,0x4); $cisd_0e = uc ascii_to_hex($cisd_0e);
seek($bin, 0x3F014, 0);read($bin, my $cisd_0l ,0x4); $cisd_0l = uc ascii_to_hex($cisd_0l);
seek($bin, 0x3F018, 0);read($bin, my $cisd_0 ,0x8); $cisd_0 = uc ascii_to_hex($cisd_0);

seek($bin, 0x3F020, 0);read($bin, my $cisd_1e ,0x4); $cisd_1e = uc ascii_to_hex($cisd_1e);
seek($bin, 0x3F024, 0);read($bin, my $cisd_1l ,0x4); $cisd_1l = uc ascii_to_hex($cisd_1l);
seek($bin, 0x3F028, 0);read($bin, my $cisd_1 ,0x8); $cisd_1 = uc ascii_to_hex($cisd_1);

seek($bin, 0x3F030, 0);read($bin, my $cisd_2e ,0x4); $cisd_2e = uc ascii_to_hex($cisd_2e);
seek($bin, 0x3F034, 0);read($bin, my $cisd_2l ,0x4); $cisd_2l = uc ascii_to_hex($cisd_2l);
seek($bin, 0x3F038, 0);read($bin, my $cisd_2 ,0x8); $cisd_2 = uc ascii_to_hex($cisd_2);

print F "<br><b>Console Individual System Data:</b><br>"; 

print F "Entries - "; if ($cisd_count eq "03") { print F "$cisd_count", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd_count<br>";}
print F "cISD Package Length - "; if ($cisd_length eq "0270") { print F "$cisd_length", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd_length<br>";}
print F "Blank Filler - "; if ($cisd_filler eq "0000000000000000") { print F $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd_filler<br>";}

print F "<br><b>cISD Entry Table:</b><br>";

print F "cISD0<br>";
print F "Entry Point - "; if ($cisd_0e eq "00000040") { print F "0040", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd_0e<br>";}
print F "Length - "; if ($cisd_0l eq "00000020") { print F "0020", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd_0l<br>";}
print F "cISD Number - "; if ($cisd_0 eq "0000000000000000") { print F "0", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd_0<br>";}

print F "<br>cISD1<br>";
print F "Entry Point - "; if ($cisd_1e eq "00000060") { print F "0060", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd_1e<br>";}
print F "Length - "; if ($cisd_1l eq "00000200") { print F "0200", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd_1l<br>";}
print F "cISD Number - "; if ($cisd_1 eq "0000000000000001") { print F "1", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd_1<br>";}

print F "<br>cISD2<br>";
print F "Entry Point - "; if ($cisd_2e eq "00000260") { print F "0260", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd_2e<br>";}
print F "Length - "; if ($cisd_2l eq "00000010") { print F "0010", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd_2l<br>";}
print F "cISD Number - "; if ($cisd_2 eq "0000000000000002") { print F "2", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd_2<br>";}

#############################################################################################################################################
print "\nChecking CISD0...\n\n"; 

seek($bin, 0x3F040, 0);read($bin, my $cisd0_mac, 0x06);
seek($bin, 0x3F04F, 0);read($bin, my $cisd0_mac_ff, 0x0A);
seek($bin, 0x3F050, 0);read($bin, my $cisd0_ff, 0x10);

print F "<br><b>CISD0:</b><br>";

my $cisd0_mac_convert = uc ascii_to_hex($cisd0_mac);
my $cisd0_mac_ff_convert = uc ascii_to_hex($cisd0_mac_ff);
my $cisd0_ff_convert = uc ascii_to_hex($cisd0_ff);

print F "MAC Address - "; if ($cisd0_mac_convert =~ m!^([0-9A-F]{2}){5}([0-9A-F]{2})$! and $cisd0_mac_ff_convert eq "FFFFFFFFFFFFFFFFFFFF") { print F "$cisd0_mac_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd0_mac_convert<br>";}
print F "Unknown Static -"; if ($cisd0_ff_convert eq "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cisd0_ff_convert<br>";}

#############################################################################################################################################
print "\nChecking CISD1...\n\n"; 

seek($bin, 0x3F060, 0);read($bin, my $cisd1_idlog, 0x04);
seek($bin, 0x3F064, 0);read($bin, my $cisd1_unknown1, 0x02);
seek($bin, 0x3F068, 0);read($bin, my $cisd1_start, 0x02);
seek($bin, 0x3F060, 0);read($bin, my $cisd1_unknown2, 0x02);
seek($bin, 0x3F06A, 0);read($bin, my $cisd1_unknown3, 0x02); 
seek($bin, 0x3F06C, 0);read($bin, my $cisd1_cid, 0x04); 
seek($bin, 0x3F070, 0);read($bin, my $cisd1_ecid, 0x20); #ascii always diff (use regex)
seek($bin, 0x3F090, 0);read($bin, my $cisd1_board_id, 0x08); #as above
seek($bin, 0x3F098, 0);read($bin, my $cisd1_kiban_id, 0x0C); #as above
seek($bin, 0x3F0A4, 0);read($bin, my $cisd1_unknown_id, 0x06); 
seek($bin, 0x3F0AA, 0);read($bin, my $cisd1_ckp2, 0x02);
seek($bin, 0x3F0AC, 0);read($bin, my $cisd1_unknown4, 0x04);
seek($bin, 0x3F0B0, 0);read($bin, my $cisd1_unknown5, 0x08); #semi diff (use regex)
seek($bin, 0x3F0B8, 0);read($bin, my $cisd1_ckp_management_id, 0x08); #always diff
seek($bin, 0x3F0C0, 0);read($bin, my $cisd1_filler, 0x1A0 ); 
seek($bin, 0x3F0C0, 0);read($bin, my $cisd1_filler2, 0x8 ); 
seek($bin, 0x3F0C8, 0);read($bin, my $cisd1_filler3, 0x198 ); 

print F "<br><b>CISD1:</b><br>";

my $cisd1_idlog_convert = uc ascii_to_hex($cisd1_idlog);
my $cisd1_unknown1_convert = uc ascii_to_hex($cisd1_unknown1);
my $cisd1_start_convert = uc ascii_to_hex($cisd1_start);
my $cisd1_unknown2_convert = uc ascii_to_hex($cisd1_unknown2);
my $cisd1_unknown3_convert = uc ascii_to_hex($cisd1_unknown3);
my $cisd1_cid_convert = uc ascii_to_hex($cisd1_cid);
my $cisd1_unknown_id_convert = uc ascii_to_hex($cisd1_unknown_id);
my $cisd1_ckp2_convert = uc ascii_to_hex($cisd1_ckp2);
my $cisd1_unknown4_convert = uc ascii_to_hex($cisd1_unknown4);
my $cisd1_unknown5_convert = uc ascii_to_hex($cisd1_unknown5);
my $cisd1_ckp_management_id_convert = uc ascii_to_hex($cisd1_ckp_management_id);
my $cisd1_filler_convert = uc ascii_to_hex($cisd1_filler);
my $cisd1_filler_convert2 = uc ascii_to_hex($cisd1_filler2);
my $cisd1_filler_convert3 = uc ascii_to_hex($cisd1_filler3);

print F "IDLog Header - "; if ($cisd1_idlog_convert eq "7F49444C") { print F "$cisd1_idlog_convert ($cisd1_idlog)", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd1_idlog_convert<br>";}
print F "Unknown Static -"; if ($cisd1_unknown1_convert eq "0002" or "0003") { print F $cisd1_unknown1_convert, $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd1_unknown1_convert<br>";}
print F "Area Start - "; if ($cisd1_start_convert eq "0100") { print F $cisd1_start_convert, $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd1_start_convert<br>";}
print F "Unknown Static - "; if ($cisd1_unknown2_convert eq "7F49") { print F $cisd1_unknown2_convert, $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd1_unknown2_convert<br>";}
print F "Unknown Static - "; if ($cisd1_unknown3_convert eq "0002" or "0001") { print F $cisd1_unknown3_convert, $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd1_unknown3_convert<br>";}
# print F "ECID - "; if ($cisd1_ecid =~ m!^01[C|D|8|E][9|A|5|F|D|C|B]\d\w\w\d\w{2}\d\w{2}[70|71]{0,2}[8|E][0|1]\w[0-1]\w{4}[0|2]0{6}[0|1|2]0*$!) { print F $cisd1_ecid, $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning $cisd1_ecid<br>";}
# print F "Board ID - "; if ($cisd1_board_id =~ m!^274[2|5|3|4|6]\d{1,5}\w\w\w$!) { print F $cisd1_board_id, $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger $cisd1_board_id<br>";}
# print F "Kiban ID - "; if ($cisd1_kiban_id =~ m!^\w{4}\d{7}\w\w*$!) { print F $cisd1_kiban_id, $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning $cisd1_kiban_id<br>";}

print F "ECID - "; if ($cisd1_ecid =~ m!^[0][1][CDE8][0459ABCDF][012][01234568C][0-9A-Z][0-9][0-9A-F][0-9A-Z][012][0-9A-F][0-9A-Z][7][01][8E][01][0-9A-Z][01][0-9A-Z][0-9A-Z][0-9A-Z][4C][02][0][0][0][0][0][0][012][0]$!) { print F $cisd1_ecid, $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning $cisd1_ecid<br>";}
print F "Board ID - "; if ($cisd1_board_id =~ m!^[2][7][4][23456][0-9][0-9][0-9][0-9]$!) { print F $cisd1_board_id, $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning $cisd1_board_id<br>";}
print F "Kiban ID - "; if ($cisd1_kiban_id =~ m!^[134][05LHJK][0-9A-Z][0-9A-Z][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9A-Z]$!) { print F $cisd1_kiban_id, $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning $cisd1_kiban_id<br>";}
print F "Unknown ID - "; if ($cisd1_unknown_id_convert =~ m!^\d\d\d\d\d\d\d\d\d\d\d\d*$!) { print F $cisd1_unknown_id_convert, $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning $cisd1_unknown_id_convert<br>";}
print F "CKP2 Data - "; if ($cisd1_ckp2_convert eq "0001") { print F $cisd1_ckp2_convert, $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd1_ckp2_convert<br>";}
print F "Unknown Static Block  -"; if ($cisd1_unknown4_convert eq "FFFFFFFF") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cisd1_unknown4_convert<br>";}
print F "Unknown Semi Static ID - "; if ($cisd1_unknown5_convert =~ m![^FF]*$!) { print F $cisd1_unknown5_convert, $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd1_unknown5_convert<br>";}
print F "CKP Management ID - "; if ($cisd1_ckp_management_id_convert =~ m![^FF]*$!) { print F $cisd1_ckp_management_id_convert, $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd1_ckp_management_id_convert<br>";}
print F "Unknown Data -"; if ($cisd1_filler_convert2 =~ m![^FF]*$!) { push(@ok, "OK"); print F $ok; $cisd1_filler_convert = $cisd1_filler_convert3 } elsif ($cisd1_filler_convert2 =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}
print F "Availiable Area -"; if ($cisd1_filler_convert =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}


#############################################################################################################################################
print "\nChecking CISD2...\n\n"; 

seek($bin, 0x3F260, 0);read($bin, my $cisd2_wlan, 0x02);
seek($bin, 0x3F262, 0);read($bin, my $cisd2_wlan00, 0x0E);
seek($bin, 0x3F270, 0);read($bin, my $cisd2_unreferenced, 0x590);

print F "<br><b>CISD2:</b><br>";

my $cisd2_wlan_convert = uc ascii_to_hex($cisd2_wlan);
my $cisd2_wlan00_convert = uc ascii_to_hex($cisd2_wlan00);
my $cisd2_unreferenced_convert = uc ascii_to_hex($cisd2_unreferenced);

print F "WLAN Channel - "; if ($cisd2_wlan_convert eq "07FF" or "1FFF") { print F "$cisd2_wlan_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cisd2_wlan_convert<br>";}
print F "WLAN Filler -"; if ($cisd2_wlan00_convert eq "0000000000000000000000000000") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cisd2_wlan00_convert<br>";}
print F "Unreferenced Area -"; if ($cisd2_unreferenced_convert =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}

##########################################################################################################################################################################################################################################################################################

seek($bin, 0x3F270, 0);read($bin, my $cisd_unrefa, 0x590); $cisd_unrefa = uc ascii_to_hex($cisd_unrefa);

print F "<br><b>CISD Unreferenced Area:</b><br>";

print F "Filled -"; if ($cisd_unrefa =~ m!^[FF]*$!) {print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}



##########################################################################################################################################################################################################################################################################################
print "\nChecking CCSD...\n\n"; 

seek($bin, 0x3F803, 0);read($bin, my $ccsd_count, 0x01);
seek($bin, 0x3F806, 0);read($bin, my $ccsd_length, 0x02);
seek($bin, 0x3F008, 0);read($bin, my $ccsd_blank ,0x08);

seek($bin, 0x3F010, 0);read($bin, my $ccsd_1 ,0x10);

seek($bin, 0x3F803, 0);read($bin, my $ccsd_count ,0x01); $ccsd_count = uc ascii_to_hex($ccsd_count);
seek($bin, 0x3F806, 0);read($bin, my $ccsd_length ,0x02); $ccsd_length = uc ascii_to_hex($ccsd_length);
seek($bin, 0x3F808, 0);read($bin, my $ccsd_filler ,0x08); $ccsd_filler = uc ascii_to_hex($ccsd_filler);

seek($bin, 0x3F810, 0);read($bin, my $ccsd_0e ,0x4); $ccsd_0e = uc ascii_to_hex($ccsd_0e);
seek($bin, 0x3F814, 0);read($bin, my $ccsd_0l ,0x4); $ccsd_0l = uc ascii_to_hex($ccsd_0l);
seek($bin, 0x3F818, 0);read($bin, my $ccsd_0 ,0x8); $ccsd_0 = uc ascii_to_hex($ccsd_0);

seek($bin, 0x3F820, 0);read($bin, my $ccsd_1e ,0x4); $ccsd_1e = uc ascii_to_hex($ccsd_1e);
seek($bin, 0x3F824, 0);read($bin, my $ccsd_1l ,0x4); $ccsd_1l = uc ascii_to_hex($ccsd_1l);
seek($bin, 0x3F828, 0);read($bin, my $ccsd_1 ,0x8); $ccsd_1 = uc ascii_to_hex($ccsd_1);

seek($bin, 0x3F830, 0);read($bin, my $ccsd_2e ,0x4); $ccsd_2e = uc ascii_to_hex($ccsd_2e);
seek($bin, 0x3F834, 0);read($bin, my $ccsd_2l ,0x4); $ccsd_2l = uc ascii_to_hex($ccsd_2l);
seek($bin, 0x3F838, 0);read($bin, my $ccsd_2 ,0x8); $ccsd_2 = uc ascii_to_hex($ccsd_2);

print F "<br><b>Common System Data:</b><br>"; 

print F "Entries - "; if ($ccsd_count eq "01") { print F "$ccsd_count", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ccsd_count<br>";}
print F "CCSD Package Length - "; if ($ccsd_length eq "0800") { print F "$ccsd_length", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ccsd_length<br>";}
print F "Blank Filler - "; if ($ccsd_filler eq "0000000000000000") { print F $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ccsd_filler<br>";}

print F "<br><b>CCSD Entry Table:</b><br>";

print F "CCSD0<br>";
print F "Entry Point - "; if ($ccsd_0e eq "00000020") { print F "0020", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ccsd_0e<br>";}
print F "Length - "; if ($ccsd_0l eq "00000030") { print F "0030", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ccsd_0l<br>";}
print F "CCSD Number - "; if ($ccsd_0 eq "0000000000000000") { print F "0", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ccsd_0<br>";}


####################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################
print "\nChecking CCSD0...\n\n"; 

seek($bin, 0x3F820, 0);read($bin, my $ccsd0_structure ,0x30);
seek($bin, 0x3F850, 0);read($bin, my $ccsd0_unreferenced ,0x7B0);

print F "<br><b>CCSD0:</b><br>";

my $ccsd0_structure_convert = uc ascii_to_hex($ccsd0_structure);
my $ccsd0_unreferenced_convert = uc ascii_to_hex($ccsd0_unreferenced);

print F "Structure -"; if ($ccsd0_structure_convert =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $ccsd0_structure_convert<br>";}

print F "<br><b>CCSD Unreferenced Area:</b><br>";
print F "Unreferenced Area -"; if ($ccsd0_unreferenced_convert =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}

####################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################
print "\nChecking TRVK_PRG0...\n\n"; 


seek($bin, 0x40000, 0);read($bin, my $trvk_prg0_filler ,0x08);
seek($bin, 0x4000E, 0);read($bin, my $trvk_prg0_datasize ,0x02);
seek($bin, 0x40010, 0);read($bin, my $trvk_prg0_header ,0x03);
seek($bin, 0x40014, 0);read($bin, my $trvk_prg0_unknown ,0x0C);
seek($bin, 0x4002F, 0);read($bin, my $trvk_prg0_metasize ,0x01);
seek($bin, 0x40210, 0);read($bin, my $trvk_prg0_unknown2 ,0x10);
seek($bin, 0x40220, 0);read($bin, my $trvk_prg0_unknown3 ,0x0C);

my $trvk_prg0_datasize_convert = uc ascii_to_hex($trvk_prg0_datasize); #02E0
my $trvk_prg0_datasize_dec = hex($trvk_prg0_datasize_convert); #736 (02E0)
my $trvk_prg0_empty_calc = ($trvk_prg0_datasize_dec + 262160); #0x40010 (header) in dec
seek($bin, $trvk_prg0_empty_calc, 0);read($bin, my $trvk_prg0_empty ,0x0D00);

seek($bin, 0x40FF0, 0);read($bin, my $trvk_prg0_filled ,0x01F010);

print F "<div id=\"frperfirmware\"></div>";
print F "<div style = \"text-align:right; float:right\"><a href=\"#Top\">Return</a></div><br>";
print F "<br><b>TRVK_PRG0:</b><br>";

my $trvk_prg0_filler_convert = uc ascii_to_hex($trvk_prg0_filler);
my $trvk_prg0_unknown_convert = uc ascii_to_hex($trvk_prg0_unknown);
my $trvk_prg0_metasize_convert = uc ascii_to_hex($trvk_prg0_metasize);
my $trvk_prg0_unknown2_convert = uc ascii_to_hex($trvk_prg0_unknown2);
my $trvk_prg0_unknown3_convert = uc ascii_to_hex($trvk_prg0_unknown3);
my $trvk_prg0_empty_convert = uc ascii_to_hex($trvk_prg0_empty);
my $trvk_prg0_filled_convert = uc ascii_to_hex($trvk_prg0_filled);

print F "Filler -"; if ($trvk_prg0_filler_convert eq "0000000000000000") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $trvk_prg0_filler_convert<br>";}
print F "Data Size - "; if ($trvk_prg0_datasize_convert ne "0000" or "FFFF" ) { print F "$trvk_prg0_datasize_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $trvk_prg0_datasize_convert<br>";}
print F "Header - "; if ($trvk_prg0_header eq "SCE") { print F "$trvk_prg0_header", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $trvk_prg0_header<br>";}
print F "Unknown -"; if ($trvk_prg0_unknown_convert eq "000000020000000200000000") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $trvk_prg0_unknown_convert<br>";}
print F "Meta Size - "; if ($trvk_prg0_metasize_convert ne "00" or "FF" ) { print F "$trvk_prg0_metasize_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $trvk_prg0_metasize_convert<br>";}
print F "Unknown 2 -"; if ($trvk_prg0_unknown2_convert =~ m!0000000\d0000000\d000\d\d\d\d\d00000000!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $trvk_prg0_unknown2_convert<br>";}
print F "Unknown 3 -"; if ($trvk_prg0_unknown3_convert =~ m!0000000\d0000000000000000!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $trvk_prg0_unknown3_convert<br>";}
print F "Empty Space -"; if ($trvk_prg0_empty_convert =~ m!^[00]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}
print F "Filled Space -"; if ($trvk_prg0_filled_convert =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}

####################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################
print "\nChecking TRVK_PRG1...\n\n"; 


seek($bin, 0x60000, 0);read($bin, my $trvk_prg1_filler ,0x08);
seek($bin, 0x6000E, 0);read($bin, my $trvk_prg1_datasize ,0x02);
seek($bin, 0x60010, 0);read($bin, my $trvk_prg1_header ,0x03);
seek($bin, 0x60014, 0);read($bin, my $trvk_prg1_unknown ,0x0C);
seek($bin, 0x6002F, 0);read($bin, my $trvk_prg1_metasize ,0x01);
seek($bin, 0x60210, 0);read($bin, my $trvk_prg1_unknown2 ,0x10);
seek($bin, 0x60220, 0);read($bin, my $trvk_prg1_unknown3 ,0x0C);

my $trvk_prg1_datasize_convert = uc ascii_to_hex($trvk_prg1_datasize); 
my $trvk_prg1_datasize_dec = hex($trvk_prg1_datasize_convert); 
my $trvk_prg1_empty_calc = ($trvk_prg1_datasize_dec + 393232); #0x60010 (header) in dec
seek($bin, $trvk_prg1_empty_calc, 0);read($bin, my $trvk_prg1_empty ,0x0D00);

seek($bin, 0x60FF0, 0);read($bin, my $trvk_prg1_filled ,0x01F010);

print F "<br><b>TRVK_PRG1:</b><br>";

my $trvk_prg1_filler_convert = uc ascii_to_hex($trvk_prg1_filler);
my $trvk_prg1_unknown_convert = uc ascii_to_hex($trvk_prg1_unknown);
my $trvk_prg1_metasize_convert = uc ascii_to_hex($trvk_prg1_metasize);
my $trvk_prg1_unknown2_convert = uc ascii_to_hex($trvk_prg1_unknown2);
my $trvk_prg1_unknown3_convert = uc ascii_to_hex($trvk_prg1_unknown3);
my $trvk_prg1_empty_convert = uc ascii_to_hex($trvk_prg1_empty);
my $trvk_prg1_filled_convert = uc ascii_to_hex($trvk_prg1_filled);

print F "Filler -"; if ($trvk_prg1_filler_convert eq "0000000000000000") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $trvk_prg1_filler_convert<br>";}
print F "Data Size - "; if ($trvk_prg1_datasize_convert ne "0000" or "FFFF" ) { print F "$trvk_prg1_datasize_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $trvk_prg1_datasize_convert<br>";}
print F "Header - "; if ($trvk_prg1_header eq "SCE") { print F "$trvk_prg1_header", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $trvk_prg1_header<br>";}
print F "Unknown -"; if ($trvk_prg1_unknown_convert eq "000000020000000200000000") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $trvk_prg1_unknown_convert<br>";}
print F "Meta Size - "; if ($trvk_prg1_metasize_convert ne "00" or "FF" ) { print F "$trvk_prg1_metasize_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $trvk_prg1_metasize_convert<br>";}
print F "Unknown 2 -"; if ($trvk_prg1_unknown2_convert =~ m!0000000\d0000000\d000\d\d\d\d\d00000000!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $trvk_prg1_unknown2_convert<br>";}
print F "Unknown 3 -"; if ($trvk_prg1_unknown3_convert =~ m!0000000\d0000000000000000!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $trvk_prg1_unknown3_convert<br>";}
print F "Empty Space -"; if ($trvk_prg1_empty_convert =~ m!^[00]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}
print F "Filled Space -"; if ($trvk_prg1_filled_convert =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}

####################################################################################################################################################################################################################################################################################################################################################################
print "\nChecking TRVK_PKG0...\n\n"; 

seek($bin, 0x80000, 0);read($bin, my $trvk_pkg0_filler ,0x08);
seek($bin, 0x8000E, 0);read($bin, my $trvk_pkg0_datasize ,0x02);
seek($bin, 0x80010, 0);read($bin, my $trvk_pkg0_header ,0x03);
seek($bin, 0x80014, 0);read($bin, my $trvk_pkg0_unknown ,0x0C);
seek($bin, 0x8002F, 0);read($bin, my $trvk_pkg0_metasize ,0x01);
seek($bin, 0x80210, 0);read($bin, my $trvk_pkg0_unknown2 ,0x10);
seek($bin, 0x80220, 0);read($bin, my $trvk_pkg0_unknown3 ,0x0C);

my $trvk_pkg0_datasize_convert = uc ascii_to_hex($trvk_pkg0_datasize); 
my $trvk_pkg0_datasize_dec = hex($trvk_pkg0_datasize_convert); 
my $trvk_pkg0_empty_calc = ($trvk_pkg0_datasize_dec + 524304); #0x80010 (header) in dec
seek($bin, $trvk_pkg0_empty_calc, 0);read($bin, my $trvk_pkg0_empty ,0x0D80);

seek($bin, 0x80FF0, 0);read($bin, my $trvk_pkg0_filled ,0x01F010);

print F "<br><b>TRVK_PKG0:</b><br>";

my $trvk_pkg0_filler_convert = uc ascii_to_hex($trvk_pkg0_filler);
my $trvk_pkg0_unknown_convert = uc ascii_to_hex($trvk_pkg0_unknown);
my $trvk_pkg0_metasize_convert = uc ascii_to_hex($trvk_pkg0_metasize);
my $trvk_pkg0_unknown2_convert = uc ascii_to_hex($trvk_pkg0_unknown2);
my $trvk_pkg0_unknown3_convert = uc ascii_to_hex($trvk_pkg0_unknown3);
my $trvk_pkg0_empty_convert = uc ascii_to_hex($trvk_pkg0_empty);
my $trvk_pkg0_filled_convert = uc ascii_to_hex($trvk_pkg0_filled);

print F "Filler -"; if ($trvk_pkg0_filler_convert eq "0000000000000000") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $trvk_pkg0_filler_convert<br>";}
print F "Data Size - "; if ($trvk_pkg0_datasize_convert ne "0000" or "FFFF" ) { print F "$trvk_pkg0_datasize_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $trvk_pkg0_datasize_convert<br>";}
print F "Header - "; if ($trvk_pkg0_header eq "SCE") { print F "$trvk_pkg0_header", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $trvk_pkg0_header<br>";}
print F "Unknown -"; if ($trvk_pkg0_unknown_convert eq "000000020000000200000000") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $trvk_pkg0_unknown_convert<br>";}
print F "Meta Size - "; if ($trvk_pkg0_metasize_convert ne "00" or "FF" ) { print F "$trvk_pkg0_metasize_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $trvk_pkg0_metasize_convert<br>";}
print F "Unknown 2 -"; if ($trvk_pkg0_unknown2_convert =~ m!0000000\d0000000\d000\d\d\d\d\d00000000!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $trvk_pkg0_unknown2_convert<br>";}
print F "Unknown 3 -"; if ($trvk_pkg0_unknown3_convert =~ m!0000000\d0000000000000000!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $trvk_pkg0_unknown3_convert<br>";}
print F "Empty Space -"; if ($trvk_pkg0_empty_convert =~ m!^[00]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}
print F "Filled Space -"; if ($trvk_pkg0_filled_convert =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}


####################################################################################################################################################################################################################################################################################################################################################################
print "\nChecking TRVK_PKG1...\n\n"; 

seek($bin, 0xA0000, 0);read($bin, my $trvk_pkg1_filler ,0x08);
seek($bin, 0xA000E, 0);read($bin, my $trvk_pkg1_datasize ,0x02);
seek($bin, 0xA0010, 0);read($bin, my $trvk_pkg1_header ,0x03);
seek($bin, 0xA0014, 0);read($bin, my $trvk_pkg1_unknown ,0x0C);
seek($bin, 0xA002F, 0);read($bin, my $trvk_pkg1_metasize ,0x01);
seek($bin, 0xA0210, 0);read($bin, my $trvk_pkg1_unknown2 ,0x10);
seek($bin, 0xA0220, 0);read($bin, my $trvk_pkg1_unknown3 ,0x0C);

my $trvk_pkg1_datasize_convert = uc ascii_to_hex($trvk_pkg1_datasize); 
my $trvk_pkg1_datasize_dec = hex($trvk_pkg1_datasize_convert); 
my $trvk_pkg1_empty_calc = ($trvk_pkg1_datasize_dec + 655376); #0xA0010 (header) in dec
seek($bin, $trvk_pkg1_empty_calc, 0);read($bin, my $trvk_pkg1_empty ,0x0D80);

seek($bin, 0xA0FF0, 0);read($bin, my $trvk_pkg1_filled ,0x01F010);

print F "<br><b>TRVK_PKG1:</b><br>";

my $trvk_pkg1_filler_convert = uc ascii_to_hex($trvk_pkg1_filler);
my $trvk_pkg1_unknown_convert = uc ascii_to_hex($trvk_pkg1_unknown);
my $trvk_pkg1_metasize_convert = uc ascii_to_hex($trvk_pkg1_metasize);
my $trvk_pkg1_unknown2_convert = uc ascii_to_hex($trvk_pkg1_unknown2);
my $trvk_pkg1_unknown3_convert = uc ascii_to_hex($trvk_pkg1_unknown3);
my $trvk_pkg1_empty_convert = uc ascii_to_hex($trvk_pkg1_empty);
my $trvk_pkg1_filled_convert = uc ascii_to_hex($trvk_pkg1_filled);

print F "Filler -"; if ($trvk_pkg1_filler_convert eq "0000000000000000") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $trvk_pkg1_filler_convert<br>";}
print F "Data Size - "; if ($trvk_pkg1_datasize_convert ne "0000" or "FFFF" ) { print F "$trvk_pkg1_datasize_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $trvk_pkg1_datasize_convert<br>";}
print F "Header - "; if ($trvk_pkg1_header eq "SCE") { print F "$trvk_pkg1_header", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $trvk_pkg1_header<br>";}
print F "Unknown -"; if ($trvk_pkg1_unknown_convert eq "000000020000000200000000") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $trvk_pkg1_unknown_convert<br>";}
print F "Meta Size - "; if ($trvk_pkg1_metasize_convert ne "00" or "FF" ) { print F "$trvk_pkg1_metasize_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $trvk_pkg1_metasize_convert<br>";}
print F "Unknown 2 -"; if ($trvk_pkg1_unknown2_convert =~ m!0000000\d0000000\d000\d\d\d\d\d00000000!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $trvk_pkg1_unknown2_convert<br>";}
print F "Unknown 3 -"; if ($trvk_pkg1_unknown3_convert =~ m!0000000\d0000000000000000!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $trvk_pkg1_unknown3_convert<br>";}
print F "Empty Space -"; if ($trvk_pkg1_empty_convert =~ m!^[00]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}
print F "Filled Space -"; if ($trvk_pkg1_filled_convert =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}

####################################################################################################################################################################################################################################################################################################################################################################
print "\nFinding ROS0/1 Versions...\n\n"; 

seek($bin, 0x0, 0);
local $/;
use bytes;
my $content = <$bin>;
print F "<br><b>ROS0/1 Versions:</b><br>"; my @es; while($content =~ m/([0-9][0-9][0-9]\.000)/g) { push @es, $1 }; if ($es[0]) { print F "$es[0]", $ok; push(@ok, "OK")} if ($es[1]) { print F "$es[1]", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - Can not find version <br><br>";}

####################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################

print "\nChecking ROS0...\n\n"; 

seek($bin, 0xC0000, 0);read($bin, my $ros0_filler, 0x0D);
seek($bin, 0xC000D, 0);read($bin, my $ros0_length, 0x03);
seek($bin, 0xC0010, 0);read($bin, my $ros0_unknown, 0x04);
seek($bin, 0xC0017, 0);read($bin, my $ros0_entrycount, 0x01);
seek($bin, 0xC001D, 0);read($bin, my $ros0_length2, 0x03);

seek($bin, 0xC0025, 0);read($bin, my $ros0_1_pos, 0x03); $ros0_1_pos = uc ascii_to_hex($ros0_1_pos);
seek($bin, 0xC002D, 0);read($bin, my $ros0_1_len, 0x03); $ros0_1_len = uc ascii_to_hex($ros0_1_len);
seek($bin, 0xC0030, 0);read($bin, my $ros0_1, 0x25);

seek($bin, 0xC0055, 0);read($bin, my $ros0_2_pos, 0x03); $ros0_2_pos = uc ascii_to_hex($ros0_2_pos);
seek($bin, 0xC005D, 0);read($bin, my $ros0_2_len, 0x03); $ros0_2_len = uc ascii_to_hex($ros0_2_len);
seek($bin, 0xC0060, 0);read($bin, my $ros0_2, 0x25);

seek($bin, 0xC0085, 0);read($bin, my $ros0_3_pos, 0x03); $ros0_3_pos = uc ascii_to_hex($ros0_3_pos);
seek($bin, 0xC008D, 0);read($bin, my $ros0_3_len, 0x03); $ros0_3_len = uc ascii_to_hex($ros0_3_len);
seek($bin, 0xC0090, 0);read($bin, my $ros0_3, 0x25);

seek($bin, 0xC00B5, 0);read($bin, my $ros0_4_pos, 0x03); $ros0_4_pos = uc ascii_to_hex($ros0_4_pos);
seek($bin, 0xC00BD, 0);read($bin, my $ros0_4_len, 0x03); $ros0_4_len = uc ascii_to_hex($ros0_4_len);
seek($bin, 0xC00C0, 0);read($bin, my $ros0_4, 0x25);

seek($bin, 0xC00E5, 0);read($bin, my $ros0_5_pos, 0x03); $ros0_5_pos = uc ascii_to_hex($ros0_5_pos);
seek($bin, 0xC00ED, 0);read($bin, my $ros0_5_len, 0x03); $ros0_5_len = uc ascii_to_hex($ros0_5_len);
seek($bin, 0xC00F0, 0);read($bin, my $ros0_5, 0x25);

seek($bin, 0xC0115, 0);read($bin, my $ros0_6_pos, 0x03); $ros0_6_pos = uc ascii_to_hex($ros0_6_pos);
seek($bin, 0xC011D, 0);read($bin, my $ros0_6_len, 0x03); $ros0_6_len = uc ascii_to_hex($ros0_6_len);
seek($bin, 0xC0120, 0);read($bin, my $ros0_6, 0x25);

seek($bin, 0xC0145, 0);read($bin, my $ros0_7_pos, 0x03); $ros0_7_pos = uc ascii_to_hex($ros0_7_pos);
seek($bin, 0xC014D, 0);read($bin, my $ros0_7_len, 0x03); $ros0_7_len = uc ascii_to_hex($ros0_7_len);
seek($bin, 0xC0150, 0);read($bin, my $ros0_7, 0x25);

seek($bin, 0xC0175, 0);read($bin, my $ros0_8_pos, 0x03); $ros0_8_pos = uc ascii_to_hex($ros0_8_pos);
seek($bin, 0xC017D, 0);read($bin, my $ros0_8_len, 0x03); $ros0_8_len = uc ascii_to_hex($ros0_8_len);
seek($bin, 0xC0180, 0);read($bin, my $ros0_8, 0x25);

seek($bin, 0xC01A5, 0);read($bin, my $ros0_9_pos, 0x03); $ros0_9_pos = uc ascii_to_hex($ros0_9_pos);
seek($bin, 0xC01AD, 0);read($bin, my $ros0_9_len, 0x03); $ros0_9_len = uc ascii_to_hex($ros0_9_len);
seek($bin, 0xC01B0, 0);read($bin, my $ros0_9, 0x25);

seek($bin, 0xC01D5, 0);read($bin, my $ros0_10_pos, 0x03); $ros0_10_pos = uc ascii_to_hex($ros0_10_pos);
seek($bin, 0xC01DD, 0);read($bin, my $ros0_10_len, 0x03); $ros0_10_len = uc ascii_to_hex($ros0_10_len);
seek($bin, 0xC01E0, 0);read($bin, my $ros0_10, 0x25);

seek($bin, 0xC0205, 0);read($bin, my $ros0_11_pos, 0x03); $ros0_11_pos = uc ascii_to_hex($ros0_11_pos);
seek($bin, 0xC020D, 0);read($bin, my $ros0_11_len, 0x03); $ros0_11_len = uc ascii_to_hex($ros0_11_len);
seek($bin, 0xC0210, 0);read($bin, my $ros0_11, 0x25);

seek($bin, 0xC0235, 0);read($bin, my $ros0_12_pos, 0x03); $ros0_12_pos = uc ascii_to_hex($ros0_12_pos);
seek($bin, 0xC023D, 0);read($bin, my $ros0_12_len, 0x03); $ros0_12_len = uc ascii_to_hex($ros0_12_len);
seek($bin, 0xC0240, 0);read($bin, my $ros0_12, 0x25);

seek($bin, 0xC0265, 0);read($bin, my $ros0_13_pos, 0x03); $ros0_13_pos = uc ascii_to_hex($ros0_13_pos);
seek($bin, 0xC026D, 0);read($bin, my $ros0_13_len, 0x03); $ros0_13_len = uc ascii_to_hex($ros0_13_len);
seek($bin, 0xC0270, 0);read($bin, my $ros0_13, 0x25);

seek($bin, 0xC0295, 0);read($bin, my $ros0_14_pos, 0x03); $ros0_14_pos = uc ascii_to_hex($ros0_14_pos);
seek($bin, 0xC029D, 0);read($bin, my $ros0_14_len, 0x03); $ros0_14_len = uc ascii_to_hex($ros0_14_len);
seek($bin, 0xC02A0, 0);read($bin, my $ros0_14, 0x25);

seek($bin, 0xC02C5, 0);read($bin, my $ros0_15_pos, 0x03); $ros0_15_pos = uc ascii_to_hex($ros0_15_pos);
seek($bin, 0xC02CD, 0);read($bin, my $ros0_15_len, 0x03); $ros0_15_len = uc ascii_to_hex($ros0_15_len);
seek($bin, 0xC02D0, 0);read($bin, my $ros0_15, 0x25);

seek($bin, 0xC02F5, 0);read($bin, my $ros0_16_pos, 0x03); $ros0_16_pos = uc ascii_to_hex($ros0_16_pos);
seek($bin, 0xC02FD, 0);read($bin, my $ros0_16_len, 0x03); $ros0_16_len = uc ascii_to_hex($ros0_16_len);
seek($bin, 0xC0300, 0);read($bin, my $ros0_16, 0x25);

seek($bin, 0xC0325, 0);read($bin, my $ros0_17_pos, 0x03); $ros0_17_pos = uc ascii_to_hex($ros0_17_pos);
seek($bin, 0xC032D, 0);read($bin, my $ros0_17_len, 0x03); $ros0_17_len = uc ascii_to_hex($ros0_17_len);
seek($bin, 0xC0330, 0);read($bin, my $ros0_17, 0x25);

seek($bin, 0xC0355, 0);read($bin, my $ros0_18_pos, 0x03); $ros0_18_pos = uc ascii_to_hex($ros0_18_pos);
seek($bin, 0xC035D, 0);read($bin, my $ros0_18_len, 0x03); $ros0_18_len = uc ascii_to_hex($ros0_18_len);
seek($bin, 0xC0360, 0);read($bin, my $ros0_18, 0x25);

seek($bin, 0xC0385, 0);read($bin, my $ros0_19_pos, 0x03); $ros0_19_pos = uc ascii_to_hex($ros0_19_pos);
seek($bin, 0xC038D, 0);read($bin, my $ros0_19_len, 0x03); $ros0_19_len = uc ascii_to_hex($ros0_19_len);
seek($bin, 0xC0390, 0);read($bin, my $ros0_19, 0x25);

seek($bin, 0xC03B5, 0);read($bin, my $ros0_20_pos, 0x03); $ros0_20_pos = uc ascii_to_hex($ros0_20_pos);
seek($bin, 0xC03BD, 0);read($bin, my $ros0_20_len, 0x03); $ros0_20_len = uc ascii_to_hex($ros0_20_len);
seek($bin, 0xC03C0, 0);read($bin, my $ros0_20, 0x25);

seek($bin, 0xC03E5, 0);read($bin, my $ros0_21_pos, 0x03); $ros0_21_pos = uc ascii_to_hex($ros0_21_pos);
seek($bin, 0xC03ED, 0);read($bin, my $ros0_21_len, 0x03); $ros0_21_len = uc ascii_to_hex($ros0_21_len);
seek($bin, 0xC03F0, 0);read($bin, my $ros0_21, 0x25);

seek($bin, 0xC0415, 0);read($bin, my $ros0_22_pos, 0x03); $ros0_22_pos = uc ascii_to_hex($ros0_22_pos);
seek($bin, 0xC041D, 0);read($bin, my $ros0_22_len, 0x03); $ros0_22_len = uc ascii_to_hex($ros0_22_len);
seek($bin, 0xC0420, 0);read($bin, my $ros0_22, 0x25);

seek($bin, 0xC0445, 0);read($bin, my $ros0_23_pos, 0x03); $ros0_23_pos = uc ascii_to_hex($ros0_23_pos);
seek($bin, 0xC044D, 0);read($bin, my $ros0_23_len, 0x03); $ros0_23_len = uc ascii_to_hex($ros0_23_len);
seek($bin, 0xC0450, 0);read($bin, my $ros0_23, 0x25);

seek($bin, 0xC0475, 0);read($bin, my $ros0_24_pos, 0x03); $ros0_24_pos = uc ascii_to_hex($ros0_24_pos);
seek($bin, 0xC047D, 0);read($bin, my $ros0_24_len, 0x03); $ros0_24_len = uc ascii_to_hex($ros0_24_len);
seek($bin, 0xC0480, 0);read($bin, my $ros0_24, 0x25);

seek($bin, 0xC04A5, 0);read($bin, my $ros0_25_pos, 0x03); $ros0_25_pos = uc ascii_to_hex($ros0_25_pos);
seek($bin, 0xC04AD, 0);read($bin, my $ros0_25_len, 0x03); $ros0_25_len = uc ascii_to_hex($ros0_25_len);
seek($bin, 0xC04B0, 0);read($bin, my $ros0_25, 0x25);

print F "<br><b>ROS0:</b><br>";

my $ros0_filler_convert = uc ascii_to_hex($ros0_filler);
my $ros0_length_convert = uc ascii_to_hex($ros0_length);
my $ros0_unknown_convert = uc ascii_to_hex($ros0_unknown);
my $ros0_entrycount_convert = uc ascii_to_hex($ros0_entrycount);
my $ros0_length2_convert = uc ascii_to_hex($ros0_length2);

print F "Header Filler -"; if ($ros0_filler_convert eq "00000000000000000000000000" ) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $ros0_filler_convert<br>";}
print F "Length of Flash Region - "; if ($ros0_length_convert eq "6FFFE0") { print F "$ros0_length_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_length_convert<br>";}
print F "Unknown Static -"; if ($ros0_unknown_convert =~ m![00000001|00000000]!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $ros0_unknown_convert<br>";}
print F "Entry Count - "; if ($ros0_entrycount_convert =~ m![18|19|20]!) { print F "$ros0_entrycount_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_entrycount_convert<br>";}
print F "Length of Flash Region 2 - "; if ($ros0_length2_convert eq "6FFFE0") { print F "$ros0_length2_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_length2_convert<br>";}

print F "<br><b>ROS0 $es[0] File Table; AuthID & MD5:</b><br>";

my $ros0_1_convert = unpack('H*', "$ros0_1"); $ros0_1_convert =~ s{00}{}g;  
my $ros0_2_convert = unpack('H*', "$ros0_2"); $ros0_2_convert =~ s{00}{}g;  
my $ros0_3_convert = unpack('H*', "$ros0_3"); $ros0_3_convert =~ s{00}{}g;  
my $ros0_4_convert = unpack('H*', "$ros0_4"); $ros0_4_convert =~ s{00}{}g;  
my $ros0_5_convert = unpack('H*', "$ros0_5"); $ros0_5_convert =~ s{00}{}g;  
my $ros0_6_convert = unpack('H*', "$ros0_6"); $ros0_6_convert =~ s{00}{}g;  
my $ros0_7_convert = unpack('H*', "$ros0_7"); $ros0_7_convert =~ s{00}{}g;  
my $ros0_8_convert = unpack('H*', "$ros0_8"); $ros0_8_convert =~ s{00}{}g;  
my $ros0_9_convert = unpack('H*', "$ros0_9"); $ros0_9_convert =~ s{00}{}g;  
my $ros0_10_convert = unpack('H*', "$ros0_10"); $ros0_10_convert =~ s{00}{}g;  
my $ros0_11_convert = unpack('H*', "$ros0_11"); $ros0_11_convert =~ s{00}{}g;  
my $ros0_12_convert = unpack('H*', "$ros0_12"); $ros0_12_convert =~ s{00}{}g;  
my $ros0_13_convert = unpack('H*', "$ros0_13"); $ros0_13_convert =~ s{00}{}g;  
my $ros0_14_convert = unpack('H*', "$ros0_14"); $ros0_14_convert =~ s{00}{}g;  
my $ros0_15_convert = unpack('H*', "$ros0_15"); $ros0_15_convert =~ s{00}{}g;  
my $ros0_16_convert = unpack('H*', "$ros0_16"); $ros0_16_convert =~ s{00}{}g;  
my $ros0_17_convert = unpack('H*', "$ros0_17"); $ros0_17_convert =~ s{00}{}g;  
my $ros0_18_convert = unpack('H*', "$ros0_18"); $ros0_18_convert =~ s{00}{}g;  
my $ros0_19_convert = unpack('H*', "$ros0_19"); $ros0_19_convert =~ s{00}{}g;  
my $ros0_20_convert = unpack('H*', "$ros0_20"); $ros0_20_convert =~ s{00}{}g;  
my $ros0_21_convert = unpack('H*', "$ros0_21"); $ros0_21_convert =~ s{00}{}g;  
my $ros0_22_convert = unpack('H*', "$ros0_22"); $ros0_22_convert =~ s{00||ff}{}g;  
my $ros0_23_convert = unpack('H*', "$ros0_23"); $ros0_23_convert =~ s{00||ff}{}g;  
my $ros0_24_convert = unpack('H*', "$ros0_24"); $ros0_24_convert =~ s{00||534345||ff}{}g;  
my $ros0_25_convert = unpack('H*', "$ros0_25"); $ros0_25_convert =~ s{00||ff}{}g;  

$ros0_1_pos = hex($ros0_1_pos); $ros0_1_pos = 786448 + $ros0_1_pos; $ros0_1_len = hex($ros0_1_len);
seek($bin, $ros0_1_pos, 0);read($bin, my $ros0_1_file, $ros0_1_len); $ros0_1_file = uc md5_hex($ros0_1_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_1_file = "No_MD5_Availiable";}

$ros0_2_pos = hex($ros0_2_pos); $ros0_2_pos = 786448 + $ros0_2_pos; $ros0_2_len = hex($ros0_2_len);
seek($bin, $ros0_2_pos, 0);read($bin, my $ros0_2_file, $ros0_2_len); $ros0_2_file = uc md5_hex($ros0_2_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_2_file = "No_MD5_Availiable";}

$ros0_3_pos = hex($ros0_3_pos); $ros0_3_pos = 786448 + $ros0_3_pos; $ros0_3_len = hex($ros0_3_len);
seek($bin, $ros0_3_pos, 0);read($bin, my $ros0_3_file, $ros0_3_len); $ros0_3_file = uc md5_hex($ros0_3_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_3_file = "No_MD5_Availiable";}

$ros0_4_pos = hex($ros0_4_pos); $ros0_4_pos = 786448 + $ros0_4_pos; $ros0_4_len = hex($ros0_4_len);
seek($bin, $ros0_4_pos, 0);read($bin, my $ros0_4_file, $ros0_4_len); $ros0_4_file = uc md5_hex($ros0_4_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_4_file = "No_MD5_Availiable";}

$ros0_5_pos = hex($ros0_5_pos); $ros0_5_pos = 786448 + $ros0_5_pos; $ros0_5_len = hex($ros0_5_len);
seek($bin, $ros0_5_pos, 0);read($bin, my $ros0_5_file, $ros0_5_len); $ros0_5_file = uc md5_hex($ros0_5_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_5_file = "No_MD5_Availiable";}

$ros0_6_pos = hex($ros0_6_pos); $ros0_6_pos = 786448 + $ros0_6_pos; $ros0_6_len = hex($ros0_6_len);
seek($bin, $ros0_6_pos, 0);read($bin, my $ros0_6_file, $ros0_6_len); $ros0_6_file = uc md5_hex($ros0_6_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_6_file = "No_MD5_Availiable";}

$ros0_7_pos = hex($ros0_7_pos); $ros0_7_pos = 786448 + $ros0_7_pos; $ros0_7_len = hex($ros0_7_len);
seek($bin, $ros0_7_pos, 0);read($bin, my $ros0_7_file, $ros0_7_len); $ros0_7_file = uc md5_hex($ros0_7_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_7_file = "No_MD5_Availiable";}

$ros0_8_pos = hex($ros0_8_pos); $ros0_8_pos = 786448 + $ros0_8_pos; $ros0_8_len = hex($ros0_8_len);
seek($bin, $ros0_8_pos, 0);read($bin, my $ros0_8_file, $ros0_8_len); $ros0_8_file = uc md5_hex($ros0_8_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_8_file = "No_MD5_Availiable";}

$ros0_9_pos = hex($ros0_9_pos); $ros0_9_pos = 786448 + $ros0_9_pos; $ros0_9_len = hex($ros0_9_len);
seek($bin, $ros0_9_pos, 0);read($bin, my $ros0_9_file, $ros0_9_len); $ros0_9_file = uc md5_hex($ros0_9_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_9_file = "No_MD5_Availiable";}

$ros0_10_pos = hex($ros0_10_pos); $ros0_10_pos = 786448 + $ros0_10_pos; $ros0_10_len = hex($ros0_10_len);
seek($bin, $ros0_10_pos, 0);read($bin, my $ros0_10_file, $ros0_10_len); $ros0_10_file = uc md5_hex($ros0_10_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_10_file = "No_MD5_Availiable";}

$ros0_11_pos = hex($ros0_11_pos); $ros0_11_pos = 786448 + $ros0_11_pos; $ros0_11_len = hex($ros0_11_len);
seek($bin, $ros0_11_pos, 0);read($bin, my $ros0_11_file, $ros0_11_len); $ros0_11_file = uc md5_hex($ros0_11_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_11_file = "No_MD5_Availiable";}

$ros0_12_pos = hex($ros0_12_pos); $ros0_12_pos = 786448 + $ros0_12_pos; $ros0_12_len = hex($ros0_12_len);
seek($bin, $ros0_12_pos, 0);read($bin, my $ros0_12_file, $ros0_12_len); $ros0_12_file = uc md5_hex($ros0_12_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_12_file = "No_MD5_Availiable";}

$ros0_13_pos = hex($ros0_13_pos); $ros0_13_pos = 786448 + $ros0_13_pos; $ros0_13_len = hex($ros0_13_len);
seek($bin, $ros0_13_pos, 0);read($bin, my $ros0_13_file, $ros0_13_len); $ros0_13_file = uc md5_hex($ros0_13_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_13_file = "No_MD5_Availiable";}

$ros0_14_pos = hex($ros0_14_pos); $ros0_14_pos = 786448 + $ros0_14_pos; $ros0_14_len = hex($ros0_14_len);
seek($bin, $ros0_14_pos, 0);read($bin, my $ros0_14_file, $ros0_14_len); $ros0_14_file = uc md5_hex($ros0_14_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_14_file = "No_MD5_Availiable";}

$ros0_15_pos = hex($ros0_15_pos); $ros0_15_pos = 786448 + $ros0_15_pos; $ros0_15_len = hex($ros0_15_len);
seek($bin, $ros0_15_pos, 0);read($bin, my $ros0_15_file, $ros0_15_len); $ros0_15_file = uc md5_hex($ros0_15_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_15_file = "No_MD5_Availiable";}

$ros0_16_pos = hex($ros0_16_pos); $ros0_16_pos = 786448 + $ros0_16_pos; $ros0_16_len = hex($ros0_16_len);
seek($bin, $ros0_16_pos, 0);read($bin, my $ros0_16_file, $ros0_16_len); $ros0_16_file = uc md5_hex($ros0_16_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_16_file = "No_MD5_Availiable";}

$ros0_17_pos = hex($ros0_17_pos); $ros0_17_pos = 786448 + $ros0_17_pos; $ros0_17_len = hex($ros0_17_len);
seek($bin, $ros0_17_pos, 0);read($bin, my $ros0_17_file, $ros0_17_len); $ros0_17_file = uc md5_hex($ros0_17_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_17_file = "No_MD5_Availiable";}

$ros0_18_pos = hex($ros0_18_pos); $ros0_18_pos = 786448 + $ros0_18_pos; $ros0_18_len = hex($ros0_18_len);
seek($bin, $ros0_18_pos, 0);read($bin, my $ros0_18_file, $ros0_18_len); $ros0_18_file = uc md5_hex($ros0_18_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_18_file = "No_MD5_Availiable";}

$ros0_19_pos = hex($ros0_19_pos); $ros0_19_pos = 786448 + $ros0_19_pos; $ros0_19_len = hex($ros0_19_len);
seek($bin, $ros0_19_pos, 0);read($bin, my $ros0_19_file, $ros0_19_len); $ros0_19_file = uc md5_hex($ros0_19_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_19_file = "No_MD5_Availiable";}

$ros0_20_pos = hex($ros0_20_pos); $ros0_20_pos = 786448 + $ros0_20_pos; $ros0_20_len = hex($ros0_20_len);
seek($bin, $ros0_20_pos, 0);read($bin, my $ros0_20_file, $ros0_20_len); $ros0_20_file = uc md5_hex($ros0_20_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_20_file = "No_MD5_Availiable";}

$ros0_21_pos = hex($ros0_21_pos); $ros0_21_pos = 786448 + $ros0_21_pos; $ros0_21_len = hex($ros0_21_len);
seek($bin, $ros0_21_pos, 0);read($bin, my $ros0_21_file, $ros0_21_len); $ros0_21_file = uc md5_hex($ros0_21_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_21_file = "No_MD5_Availiable";}

$ros0_22_pos = hex($ros0_22_pos); $ros0_22_pos = 786448 + $ros0_22_pos; $ros0_22_len = hex($ros0_22_len);
seek($bin, $ros0_22_pos, 0);read($bin, my $ros0_22_file, $ros0_22_len); $ros0_22_file = uc md5_hex($ros0_22_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_22_file = "No_MD5_Availiable";}

$ros0_23_pos = hex($ros0_23_pos); $ros0_23_pos = 786448 + $ros0_23_pos; $ros0_23_len = hex($ros0_23_len);
seek($bin, $ros0_23_pos, 0);read($bin, my $ros0_23_file, $ros0_23_len); $ros0_23_file = uc md5_hex($ros0_23_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_23_file = "No_MD5_Availiable";}

$ros0_24_pos = hex($ros0_24_pos); $ros0_24_pos = 786448 + $ros0_24_pos; $ros0_24_len = hex($ros0_24_len);
seek($bin, $ros0_24_pos, 0);read($bin, my $ros0_24_file, $ros0_24_len); $ros0_24_file = uc md5_hex($ros0_24_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_24_file = "No_MD5_Availiable";}

$ros0_25_pos = hex($ros0_25_pos); $ros0_25_pos = 786448 + $ros0_25_pos; $ros0_25_len = hex($ros0_25_len);
seek($bin, $ros0_25_pos, 0);read($bin, my $ros0_25_file, $ros0_25_len); $ros0_25_file = uc md5_hex($ros0_25_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros0_25_file = "No_MD5_Availiable";}

my $ros0_1_authidpos = $ros0_1_pos + 112; seek($bin, $ros0_1_authidpos, 0);read($bin, my $ros0_1_authid, 0x8); $ros0_1_authid = uc ascii_to_hex($ros0_1_authid); if (exists $ros_not_self{$ros0_1_convert}) {$ros0_1_authid = "N/A"};
my $ros0_2_authidpos = $ros0_2_pos + 112; seek($bin, $ros0_2_authidpos, 0);read($bin, my $ros0_2_authid, 0x8); $ros0_2_authid = uc ascii_to_hex($ros0_2_authid); if (exists $ros_not_self{$ros0_2_convert}) {$ros0_2_authid = "N/A"};
my $ros0_3_authidpos = $ros0_3_pos + 112; seek($bin, $ros0_3_authidpos, 0);read($bin, my $ros0_3_authid, 0x8); $ros0_3_authid = uc ascii_to_hex($ros0_3_authid); if (exists $ros_not_self{$ros0_3_convert}) {$ros0_3_authid = "N/A"};
my $ros0_4_authidpos = $ros0_4_pos + 112; seek($bin, $ros0_4_authidpos, 0);read($bin, my $ros0_4_authid, 0x8); $ros0_4_authid = uc ascii_to_hex($ros0_4_authid); if (exists $ros_not_self{$ros0_4_convert}) {$ros0_4_authid = "N/A"};
my $ros0_5_authidpos = $ros0_5_pos + 112; seek($bin, $ros0_5_authidpos, 0);read($bin, my $ros0_5_authid, 0x8); $ros0_5_authid = uc ascii_to_hex($ros0_5_authid); if (exists $ros_not_self{$ros0_5_convert}) {$ros0_5_authid = "N/A"};
my $ros0_6_authidpos = $ros0_6_pos + 112; seek($bin, $ros0_6_authidpos, 0);read($bin, my $ros0_6_authid, 0x8); $ros0_6_authid = uc ascii_to_hex($ros0_6_authid); if (exists $ros_not_self{$ros0_6_convert}) {$ros0_6_authid = "N/A"};
my $ros0_7_authidpos = $ros0_7_pos + 112; seek($bin, $ros0_7_authidpos, 0);read($bin, my $ros0_7_authid, 0x8); $ros0_7_authid = uc ascii_to_hex($ros0_7_authid); if (exists $ros_not_self{$ros0_7_convert}) {$ros0_7_authid = "N/A"};
my $ros0_8_authidpos = $ros0_8_pos + 112; seek($bin, $ros0_8_authidpos, 0);read($bin, my $ros0_8_authid, 0x8); $ros0_8_authid = uc ascii_to_hex($ros0_8_authid); if (exists $ros_not_self{$ros0_8_convert}) {$ros0_8_authid = "N/A"};
my $ros0_9_authidpos = $ros0_9_pos + 112; seek($bin, $ros0_9_authidpos, 0);read($bin, my $ros0_9_authid, 0x8); $ros0_9_authid = uc ascii_to_hex($ros0_9_authid); if (exists $ros_not_self{$ros0_9_convert}) {$ros0_9_authid = "N/A"};
my $ros0_10_authidpos = $ros0_10_pos + 112; seek($bin, $ros0_10_authidpos, 0);read($bin, my $ros0_10_authid, 0x8); $ros0_10_authid = uc ascii_to_hex($ros0_10_authid); if (exists $ros_not_self{$ros0_10_convert}) {$ros0_10_authid = "N/A"};
my $ros0_11_authidpos = $ros0_11_pos + 112; seek($bin, $ros0_11_authidpos, 0);read($bin, my $ros0_11_authid, 0x8); $ros0_11_authid = uc ascii_to_hex($ros0_11_authid); if (exists $ros_not_self{$ros0_11_convert}) {$ros0_11_authid = "N/A"};
my $ros0_12_authidpos = $ros0_12_pos + 112; seek($bin, $ros0_12_authidpos, 0);read($bin, my $ros0_12_authid, 0x8); $ros0_12_authid = uc ascii_to_hex($ros0_12_authid); if (exists $ros_not_self{$ros0_12_convert}) {$ros0_12_authid = "N/A"};
my $ros0_13_authidpos = $ros0_13_pos + 112; seek($bin, $ros0_13_authidpos, 0);read($bin, my $ros0_13_authid, 0x8); $ros0_13_authid = uc ascii_to_hex($ros0_13_authid); if (exists $ros_not_self{$ros0_13_convert}) {$ros0_13_authid = "N/A"};
my $ros0_14_authidpos = $ros0_14_pos + 112; seek($bin, $ros0_14_authidpos, 0);read($bin, my $ros0_14_authid, 0x8); $ros0_14_authid = uc ascii_to_hex($ros0_14_authid); if (exists $ros_not_self{$ros0_14_convert}) {$ros0_14_authid = "N/A"};
my $ros0_15_authidpos = $ros0_15_pos + 112; seek($bin, $ros0_15_authidpos, 0);read($bin, my $ros0_15_authid, 0x8); $ros0_15_authid = uc ascii_to_hex($ros0_15_authid); if (exists $ros_not_self{$ros0_15_convert}) {$ros0_15_authid = "N/A"};
my $ros0_16_authidpos = $ros0_16_pos + 112; seek($bin, $ros0_16_authidpos, 0);read($bin, my $ros0_16_authid, 0x8); $ros0_16_authid = uc ascii_to_hex($ros0_16_authid); if (exists $ros_not_self{$ros0_16_convert}) {$ros0_16_authid = "N/A"};
my $ros0_17_authidpos = $ros0_17_pos + 112; seek($bin, $ros0_17_authidpos, 0);read($bin, my $ros0_17_authid, 0x8); $ros0_17_authid = uc ascii_to_hex($ros0_17_authid); if (exists $ros_not_self{$ros0_17_convert}) {$ros0_17_authid = "N/A"};
my $ros0_18_authidpos = $ros0_18_pos + 112; seek($bin, $ros0_18_authidpos, 0);read($bin, my $ros0_18_authid, 0x8); $ros0_18_authid = uc ascii_to_hex($ros0_18_authid); if (exists $ros_not_self{$ros0_18_convert}) {$ros0_18_authid = "N/A"};
my $ros0_19_authidpos = $ros0_19_pos + 112; seek($bin, $ros0_19_authidpos, 0);read($bin, my $ros0_19_authid, 0x8); $ros0_19_authid = uc ascii_to_hex($ros0_19_authid); if (exists $ros_not_self{$ros0_19_convert}) {$ros0_19_authid = "N/A"};
my $ros0_20_authidpos = $ros0_20_pos + 112; seek($bin, $ros0_20_authidpos, 0);read($bin, my $ros0_20_authid, 0x8); $ros0_20_authid = uc ascii_to_hex($ros0_20_authid); if (exists $ros_not_self{$ros0_20_convert}) {$ros0_20_authid = "N/A"};
my $ros0_21_authidpos = $ros0_21_pos + 112; seek($bin, $ros0_21_authidpos, 0);read($bin, my $ros0_21_authid, 0x8); $ros0_21_authid = uc ascii_to_hex($ros0_21_authid); if (exists $ros_not_self{$ros0_21_convert}) {$ros0_21_authid = "N/A"};
my $ros0_22_authidpos = $ros0_22_pos + 112; seek($bin, $ros0_22_authidpos, 0);read($bin, my $ros0_22_authid, 0x8); $ros0_22_authid = uc ascii_to_hex($ros0_22_authid); if (exists $ros_not_self{$ros0_22_convert}) {$ros0_22_authid = "N/A"};
my $ros0_23_authidpos = $ros0_23_pos + 112; seek($bin, $ros0_23_authidpos, 0);read($bin, my $ros0_23_authid, 0x8); $ros0_23_authid = uc ascii_to_hex($ros0_23_authid); if (exists $ros_not_self{$ros0_23_convert}) {$ros0_23_authid = "N/A"};
my $ros0_24_authidpos = $ros0_24_pos + 112; seek($bin, $ros0_24_authidpos, 0);read($bin, my $ros0_24_authid, 0x8); $ros0_24_authid = uc ascii_to_hex($ros0_24_authid); if (exists $ros_not_self{$ros0_24_convert}) {$ros0_24_authid = "N/A"};
my $ros0_25_authidpos = $ros0_25_pos + 112; seek($bin, $ros0_25_authidpos, 0);read($bin, my $ros0_25_authid, 0x8); $ros0_25_authid = uc ascii_to_hex($ros0_25_authid); if (exists $ros_not_self{$ros0_25_convert}) {$ros0_25_authid = "N/A"};

if ( $ros_list{$ros0_1_convert}) { print F "$ros_list{$ros0_1_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_1_convert}<br>";}
if ( $auth_id_list_nn{$ros0_1_authid}) { print F "AuthID: $ros0_1_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_1_authid<br>";}
if (exists $ros_md5_file{$ros0_1_file}) { print F "MD5: $ros0_1_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_1_file<br><br>";}
if ( $ros_list{$ros0_2_convert}) { print F "$ros_list{$ros0_2_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_2_convert}<br>";}
if ( $auth_id_list_nn{$ros0_2_authid}) { print F "AuthID: $ros0_2_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_2_authid<br>";}
if (exists $ros_md5_file{$ros0_2_file}) { print F "MD5: $ros0_2_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_2_file<br><br>";}
if ( $ros_list{$ros0_3_convert}) { print F "$ros_list{$ros0_3_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_3_convert}<br>";}
if ( $auth_id_list_nn{$ros0_3_authid}) { print F "AuthID: $ros0_3_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_3_authid<br>";}
if (exists $ros_md5_file{$ros0_3_file}) { print F "MD5: $ros0_3_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_3_file<br><br>";}
if ( $ros_list{$ros0_4_convert}) { print F "$ros_list{$ros0_4_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_4_convert}<br>";}
if ( $auth_id_list_nn{$ros0_4_authid}) { print F "AuthID: $ros0_4_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_4_authid<br>";}
if (exists $ros_md5_file{$ros0_4_file}) { print F "MD5: $ros0_4_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_4_file<br><br>";}
if ( $ros_list{$ros0_5_convert}) { print F "$ros_list{$ros0_5_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_5_convert}<br>";}
if ( $auth_id_list_nn{$ros0_5_authid}) { print F "AuthID: $ros0_5_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_5_authid<br>";}
if (exists $ros_md5_file{$ros0_5_file}) { print F "MD5: $ros0_5_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_5_file<br><br>";}
if ( $ros_list{$ros0_6_convert}) { print F "$ros_list{$ros0_6_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_6_convert}<br>";}
if ( $auth_id_list_nn{$ros0_6_authid}) { print F "AuthID: $ros0_6_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_6_authid<br>";}
if (exists $ros_md5_file{$ros0_6_file}) { print F "MD5: $ros0_6_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_6_file<br><br>";}
if ( $ros_list{$ros0_7_convert}) { print F "$ros_list{$ros0_7_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_7_convert}<br>";}
if ( $auth_id_list_nn{$ros0_7_authid}) { print F "AuthID: $ros0_7_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_7_authid<br>";}
if (exists $ros_md5_file{$ros0_7_file}) { print F "MD5: $ros0_7_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_7_file<br><br>";}
if ( $ros_list{$ros0_8_convert}) { print F "$ros_list{$ros0_8_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_8_convert}<br>";}
if ( $auth_id_list_nn{$ros0_8_authid}) { print F "AuthID: $ros0_8_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_8_authid<br>";}
if (exists $ros_md5_file{$ros0_8_file}) { print F "MD5: $ros0_8_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_8_file<br><br>";}
if ( $ros_list{$ros0_9_convert}) { print F "$ros_list{$ros0_9_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_9_convert}<br>";}
if ( $auth_id_list_nn{$ros0_9_authid}) { print F "AuthID: $ros0_9_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_9_authid<br>";}
if (exists $ros_md5_file{$ros0_9_file}) { print F "MD5: $ros0_9_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_9_file<br><br>";}
if ( $ros_list{$ros0_10_convert}) { print F "$ros_list{$ros0_10_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_10_convert}<br>";}
if ( $auth_id_list_nn{$ros0_10_authid}) { print F "AuthID: $ros0_10_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_10_authid<br>";}
if (exists $ros_md5_file{$ros0_10_file}) { print F "MD5: $ros0_10_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_10_file<br><br>";}
if ( $ros_list{$ros0_11_convert}) { print F "$ros_list{$ros0_11_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_11_convert}<br>";}
if ( $auth_id_list_nn{$ros0_11_authid}) { print F "AuthID: $ros0_11_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_11_authid<br>";}
if (exists $ros_md5_file{$ros0_11_file}) { print F "MD5: $ros0_11_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_11_file<br><br>";}
if ( $ros_list{$ros0_12_convert}) { print F "$ros_list{$ros0_12_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_12_convert}<br>";}
if ( $auth_id_list_nn{$ros0_12_authid}) { print F "AuthID: $ros0_12_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_12_authid<br>";}
if (exists $ros_md5_file{$ros0_12_file}) { print F "MD5: $ros0_12_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_12_file<br><br>";}
if ( $ros_list{$ros0_13_convert}) { print F "$ros_list{$ros0_13_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_13_convert}<br>";}
if ( $auth_id_list_nn{$ros0_13_authid}) { print F "AuthID: $ros0_13_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_13_authid<br>";}
if (exists $ros_md5_file{$ros0_13_file}) { print F "MD5: $ros0_13_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_13_file<br><br>";}
if ( $ros_list{$ros0_14_convert}) { print F "$ros_list{$ros0_14_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_14_convert}<br>";}
if ( $auth_id_list_nn{$ros0_14_authid}) { print F "AuthID: $ros0_14_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_14_authid<br>";}
if (exists $ros_md5_file{$ros0_14_file}) { print F "MD5: $ros0_14_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_14_file<br><br>";}
if ( $ros_list{$ros0_15_convert}) { print F "$ros_list{$ros0_15_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_15_convert}<br>";}
if ( $auth_id_list_nn{$ros0_15_authid}) { print F "AuthID: $ros0_15_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_15_authid<br>";}
if (exists $ros_md5_file{$ros0_15_file}) { print F "MD5: $ros0_15_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_15_file<br><br>";}
if ( $ros_list{$ros0_16_convert}) { print F "$ros_list{$ros0_16_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_16_convert}<br>";}
if ( $auth_id_list_nn{$ros0_16_authid}) { print F "AuthID: $ros0_16_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_16_authid<br>";}
if (exists $ros_md5_file{$ros0_16_file}) { print F "MD5: $ros0_16_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_16_file<br><br>";}
if ( $ros_list{$ros0_17_convert}) { print F "$ros_list{$ros0_17_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_17_convert}<br>";}
if ( $auth_id_list_nn{$ros0_17_authid}) { print F "AuthID: $ros0_17_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_17_authid<br>";}
if (exists $ros_md5_file{$ros0_17_file}) { print F "MD5: $ros0_17_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_17_file<br><br>";}
if ( $ros_list{$ros0_18_convert}) { print F "$ros_list{$ros0_18_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_18_convert}<br>";}
if ( $auth_id_list_nn{$ros0_18_authid}) { print F "AuthID: $ros0_18_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_18_authid<br>";}
if (exists $ros_md5_file{$ros0_18_file}) { print F "MD5: $ros0_18_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_18_file<br><br>";}
if ( $ros_list{$ros0_19_convert}) { print F "$ros_list{$ros0_19_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_19_convert}<br>";}
if ( $auth_id_list_nn{$ros0_19_authid}) { print F "AuthID: $ros0_19_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_19_authid<br>";}
if (exists $ros_md5_file{$ros0_19_file}) { print F "MD5: $ros0_19_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_19_file<br><br>";}
if ( $ros_list{$ros0_20_convert}) { print F "$ros_list{$ros0_20_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_20_convert}<br>";}
if ( $auth_id_list_nn{$ros0_20_authid}) { print F "AuthID: $ros0_20_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_20_authid<br>";}
if (exists $ros_md5_file{$ros0_20_file}) { print F "MD5: $ros0_20_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_20_file<br><br>";}
if ( $ros_list{$ros0_21_convert}) { print F "$ros_list{$ros0_21_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_21_convert}<br>";}
if ( $auth_id_list_nn{$ros0_21_authid}) { print F "AuthID: $ros0_21_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_21_authid<br>";}
if (exists $ros_md5_file{$ros0_21_file}) { print F "MD5: $ros0_21_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_21_file<br><br>";}
if ( $ros_list{$ros0_22_convert}) { print F "$ros_list{$ros0_22_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_22_convert}<br>";}
if ( $auth_id_list_nn{$ros0_22_authid}) { print F "AuthID: $ros0_22_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_22_authid<br>";}
if (exists $ros_md5_file{$ros0_22_file}) { print F "MD5: $ros0_22_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_22_file<br><br>";}

if ($ros0_23_convert eq 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff' or ' ') {} else {
if ( $ros_list{$ros0_23_convert}) { print F "$ros_list{$ros0_23_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_23_convert}<br>";}
if ( $auth_id_list_nn{$ros0_23_authid}) { print F "AuthID: $ros0_23_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_23_authid<br>";}
if (exists $ros_md5_file{$ros0_23_file}) { print F "MD5: $ros0_23_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_23_file<br><br>";}
}

if ($ros0_24_convert eq 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff' or ' ') {} else {
if ( $ros_list{$ros0_24_convert}) { print F "$ros_list{$ros0_24_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_24_convert}<br>";}
if ( $auth_id_list_nn{$ros0_24_authid}) { print F "AuthID: $ros0_24_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_24_authid<br>";}
if (exists $ros_md5_file{$ros0_24_file}) { print F "MD5: $ros0_24_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_24_file<br><br>";}
}

if ($ros0_25_convert eq '063c980370' or 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff' or ' ') {} else {
if ( $ros_list{$ros0_25_convert}) { print F "$ros_list{$ros0_25_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros0_25_convert}<br>";}
if ( $auth_id_list_nn{$ros0_25_authid}) { print F "AuthID: $ros0_25_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_25_authid<br>";}
if (exists $ros_md5_file{$ros0_25_file}) { print F "MD5: $ros0_25_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros0_25_file<br><br>";}
}

####################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################
print "\nChecking ROS1...\n\n"; 

seek($bin, 0x7C0000, 0);read($bin, my $ros1_filler, 0x0D);
seek($bin, 0x7C000D, 0);read($bin, my $ros1_length, 0x03);
seek($bin, 0x7C0010, 0);read($bin, my $ros1_unknown, 0x04);
seek($bin, 0x7C0017, 0);read($bin, my $ros1_entrycount, 0x01);
seek($bin, 0x7C001D, 0);read($bin, my $ros1_length2, 0x03);

seek($bin, 0x7C0025, 0);read($bin, my $ros1_1_pos, 0x03); $ros1_1_pos = uc ascii_to_hex($ros1_1_pos);
seek($bin, 0x7C002D, 0);read($bin, my $ros1_1_len, 0x03); $ros1_1_len = uc ascii_to_hex($ros1_1_len);
seek($bin, 0x7C0030, 0);read($bin, my $ros1_1, 0x25);

seek($bin, 0x7C0055, 0);read($bin, my $ros1_2_pos, 0x03); $ros1_2_pos = uc ascii_to_hex($ros1_2_pos);
seek($bin, 0x7C005D, 0);read($bin, my $ros1_2_len, 0x03); $ros1_2_len = uc ascii_to_hex($ros1_2_len);
seek($bin, 0x7C0060, 0);read($bin, my $ros1_2, 0x25);

seek($bin, 0x7C0085, 0);read($bin, my $ros1_3_pos, 0x03); $ros1_3_pos = uc ascii_to_hex($ros1_3_pos);
seek($bin, 0x7C008D, 0);read($bin, my $ros1_3_len, 0x03); $ros1_3_len = uc ascii_to_hex($ros1_3_len);
seek($bin, 0x7C0090, 0);read($bin, my $ros1_3, 0x25);

seek($bin, 0x7C00B5, 0);read($bin, my $ros1_4_pos, 0x03); $ros1_4_pos = uc ascii_to_hex($ros1_4_pos);
seek($bin, 0x7C00BD, 0);read($bin, my $ros1_4_len, 0x03); $ros1_4_len = uc ascii_to_hex($ros1_4_len);
seek($bin, 0x7C00C0, 0);read($bin, my $ros1_4, 0x25);

seek($bin, 0x7C00E5, 0);read($bin, my $ros1_5_pos, 0x03); $ros1_5_pos = uc ascii_to_hex($ros1_5_pos);
seek($bin, 0x7C00ED, 0);read($bin, my $ros1_5_len, 0x03); $ros1_5_len = uc ascii_to_hex($ros1_5_len);
seek($bin, 0x7C00F0, 0);read($bin, my $ros1_5, 0x25);

seek($bin, 0x7C0115, 0);read($bin, my $ros1_6_pos, 0x03); $ros1_6_pos = uc ascii_to_hex($ros1_6_pos);
seek($bin, 0x7C011D, 0);read($bin, my $ros1_6_len, 0x03); $ros1_6_len = uc ascii_to_hex($ros1_6_len);
seek($bin, 0x7C0120, 0);read($bin, my $ros1_6, 0x25);

seek($bin, 0x7C0145, 0);read($bin, my $ros1_7_pos, 0x03); $ros1_7_pos = uc ascii_to_hex($ros1_7_pos);
seek($bin, 0x7C014D, 0);read($bin, my $ros1_7_len, 0x03); $ros1_7_len = uc ascii_to_hex($ros1_7_len);
seek($bin, 0x7C0150, 0);read($bin, my $ros1_7, 0x25);

seek($bin, 0x7C0175, 0);read($bin, my $ros1_8_pos, 0x03); $ros1_8_pos = uc ascii_to_hex($ros1_8_pos);
seek($bin, 0x7C017D, 0);read($bin, my $ros1_8_len, 0x03); $ros1_8_len = uc ascii_to_hex($ros1_8_len);
seek($bin, 0x7C0180, 0);read($bin, my $ros1_8, 0x25);

seek($bin, 0x7C01A5, 0);read($bin, my $ros1_9_pos, 0x03); $ros1_9_pos = uc ascii_to_hex($ros1_9_pos);
seek($bin, 0x7C01AD, 0);read($bin, my $ros1_9_len, 0x03); $ros1_9_len = uc ascii_to_hex($ros1_9_len);
seek($bin, 0x7C01B0, 0);read($bin, my $ros1_9, 0x25);

seek($bin, 0x7C01D5, 0);read($bin, my $ros1_10_pos, 0x03); $ros1_10_pos = uc ascii_to_hex($ros1_10_pos);
seek($bin, 0x7C01DD, 0);read($bin, my $ros1_10_len, 0x03); $ros1_10_len = uc ascii_to_hex($ros1_10_len);
seek($bin, 0x7C01E0, 0);read($bin, my $ros1_10, 0x25);

seek($bin, 0x7C0205, 0);read($bin, my $ros1_11_pos, 0x03); $ros1_11_pos = uc ascii_to_hex($ros1_11_pos);
seek($bin, 0x7C020D, 0);read($bin, my $ros1_11_len, 0x03); $ros1_11_len = uc ascii_to_hex($ros1_11_len);
seek($bin, 0x7C0210, 0);read($bin, my $ros1_11, 0x25);

seek($bin, 0x7C0235, 0);read($bin, my $ros1_12_pos, 0x03); $ros1_12_pos = uc ascii_to_hex($ros1_12_pos);
seek($bin, 0x7C023D, 0);read($bin, my $ros1_12_len, 0x03); $ros1_12_len = uc ascii_to_hex($ros1_12_len);
seek($bin, 0x7C0240, 0);read($bin, my $ros1_12, 0x25);

seek($bin, 0x7C0265, 0);read($bin, my $ros1_13_pos, 0x03); $ros1_13_pos = uc ascii_to_hex($ros1_13_pos);
seek($bin, 0x7C026D, 0);read($bin, my $ros1_13_len, 0x03); $ros1_13_len = uc ascii_to_hex($ros1_13_len);
seek($bin, 0x7C0270, 0);read($bin, my $ros1_13, 0x25);

seek($bin, 0x7C0295, 0);read($bin, my $ros1_14_pos, 0x03); $ros1_14_pos = uc ascii_to_hex($ros1_14_pos);
seek($bin, 0x7C029D, 0);read($bin, my $ros1_14_len, 0x03); $ros1_14_len = uc ascii_to_hex($ros1_14_len);
seek($bin, 0x7C02A0, 0);read($bin, my $ros1_14, 0x25);

seek($bin, 0x7C02C5, 0);read($bin, my $ros1_15_pos, 0x03); $ros1_15_pos = uc ascii_to_hex($ros1_15_pos);
seek($bin, 0x7C02CD, 0);read($bin, my $ros1_15_len, 0x03); $ros1_15_len = uc ascii_to_hex($ros1_15_len);
seek($bin, 0x7C02D0, 0);read($bin, my $ros1_15, 0x25);

seek($bin, 0x7C02F5, 0);read($bin, my $ros1_16_pos, 0x03); $ros1_16_pos = uc ascii_to_hex($ros1_16_pos);
seek($bin, 0x7C02FD, 0);read($bin, my $ros1_16_len, 0x03); $ros1_16_len = uc ascii_to_hex($ros1_16_len);
seek($bin, 0x7C0300, 0);read($bin, my $ros1_16, 0x25);

seek($bin, 0x7C0325, 0);read($bin, my $ros1_17_pos, 0x03); $ros1_17_pos = uc ascii_to_hex($ros1_17_pos);
seek($bin, 0x7C032D, 0);read($bin, my $ros1_17_len, 0x03); $ros1_17_len = uc ascii_to_hex($ros1_17_len);
seek($bin, 0x7C0330, 0);read($bin, my $ros1_17, 0x25);

seek($bin, 0x7C0355, 0);read($bin, my $ros1_18_pos, 0x03); $ros1_18_pos = uc ascii_to_hex($ros1_18_pos);
seek($bin, 0x7C035D, 0);read($bin, my $ros1_18_len, 0x03); $ros1_18_len = uc ascii_to_hex($ros1_18_len);
seek($bin, 0x7C0360, 0);read($bin, my $ros1_18, 0x25);

seek($bin, 0x7C0385, 0);read($bin, my $ros1_19_pos, 0x03); $ros1_19_pos = uc ascii_to_hex($ros1_19_pos);
seek($bin, 0x7C038D, 0);read($bin, my $ros1_19_len, 0x03); $ros1_19_len = uc ascii_to_hex($ros1_19_len);
seek($bin, 0x7C0390, 0);read($bin, my $ros1_19, 0x25);

seek($bin, 0x7C03B5, 0);read($bin, my $ros1_20_pos, 0x03); $ros1_20_pos = uc ascii_to_hex($ros1_20_pos);
seek($bin, 0x7C03BD, 0);read($bin, my $ros1_20_len, 0x03); $ros1_20_len = uc ascii_to_hex($ros1_20_len);
seek($bin, 0x7C03C0, 0);read($bin, my $ros1_20, 0x25);

seek($bin, 0x7C03E5, 0);read($bin, my $ros1_21_pos, 0x03); $ros1_21_pos = uc ascii_to_hex($ros1_21_pos);
seek($bin, 0x7C03ED, 0);read($bin, my $ros1_21_len, 0x03); $ros1_21_len = uc ascii_to_hex($ros1_21_len);
seek($bin, 0x7C03F0, 0);read($bin, my $ros1_21, 0x25);

seek($bin, 0x7C0415, 0);read($bin, my $ros1_22_pos, 0x03); $ros1_22_pos = uc ascii_to_hex($ros1_22_pos);
seek($bin, 0x7C041D, 0);read($bin, my $ros1_22_len, 0x03); $ros1_22_len = uc ascii_to_hex($ros1_22_len);
seek($bin, 0x7C0420, 0);read($bin, my $ros1_22, 0x25);

seek($bin, 0x7C0445, 0);read($bin, my $ros1_23_pos, 0x03); $ros1_23_pos = uc ascii_to_hex($ros1_23_pos);
seek($bin, 0x7C044D, 0);read($bin, my $ros1_23_len, 0x03); $ros1_23_len = uc ascii_to_hex($ros1_23_len);
seek($bin, 0x7C0450, 0);read($bin, my $ros1_23, 0x25);

seek($bin, 0x7C0475, 0);read($bin, my $ros1_24_pos, 0x03); $ros1_24_pos = uc ascii_to_hex($ros1_24_pos);
seek($bin, 0x7C047D, 0);read($bin, my $ros1_24_len, 0x03); $ros1_24_len = uc ascii_to_hex($ros1_24_len);
seek($bin, 0x7C0480, 0);read($bin, my $ros1_24, 0x25);

seek($bin, 0x7C04A5, 0);read($bin, my $ros1_25_pos, 0x03); $ros1_25_pos = uc ascii_to_hex($ros1_25_pos);
seek($bin, 0x7C04AD, 0);read($bin, my $ros1_25_len, 0x03); $ros1_25_len = uc ascii_to_hex($ros1_25_len);
seek($bin, 0x7C04B0, 0);read($bin, my $ros1_25, 0x25);

print F "<br><b>ROS1:</b><br>";

my $ros1_filler_convert = uc ascii_to_hex($ros1_filler);
my $ros1_length_convert = uc ascii_to_hex($ros1_length);
my $ros1_unknown_convert = uc ascii_to_hex($ros1_unknown);
my $ros1_entrycount_convert = uc ascii_to_hex($ros1_entrycount);
my $ros1_length2_convert = uc ascii_to_hex($ros1_length2);

print F "Header Filler -"; if ($ros1_filler_convert eq "00000000000000000000000000" ) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $ros1_filler_convert<br>";}
print F "Length of Flash Region - "; if ($ros1_length_convert eq "6FFFE0") { print F "$ros1_length_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_length_convert<br>";}
print F "Unknown Static -"; if ($ros1_unknown_convert eq "00000001") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $ros1_unknown_convert<br>";}
print F "Entry Count - "; if ($ros1_entrycount_convert =~ m![18|19|20]!) { print F "$ros1_entrycount_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_entrycount_convert<br>";}
print F "Length of Flash Region 2 - "; if ($ros1_length2_convert eq "6FFFE0") { print F "$ros1_length2_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_length2_convert<br>";}

print F "<br><b>ROS1 $es[1] File Table; AuthID & MD5:</b><br>";

my $ros1_1_convert = unpack('H*', "$ros1_1"); $ros1_1_convert =~ s{00}{}g;  
my $ros1_2_convert = unpack('H*', "$ros1_2"); $ros1_2_convert =~ s{00}{}g;  
my $ros1_3_convert = unpack('H*', "$ros1_3"); $ros1_3_convert =~ s{00}{}g;  
my $ros1_4_convert = unpack('H*', "$ros1_4"); $ros1_4_convert =~ s{00}{}g;  
my $ros1_5_convert = unpack('H*', "$ros1_5"); $ros1_5_convert =~ s{00}{}g;  
my $ros1_6_convert = unpack('H*', "$ros1_6"); $ros1_6_convert =~ s{00}{}g;  
my $ros1_7_convert = unpack('H*', "$ros1_7"); $ros1_7_convert =~ s{00}{}g;  
my $ros1_8_convert = unpack('H*', "$ros1_8"); $ros1_8_convert =~ s{00}{}g;  
my $ros1_9_convert = unpack('H*', "$ros1_9"); $ros1_9_convert =~ s{00}{}g;  
my $ros1_10_convert = unpack('H*', "$ros1_10"); $ros1_10_convert =~ s{00}{}g;  
my $ros1_11_convert = unpack('H*', "$ros1_11"); $ros1_11_convert =~ s{00}{}g;  
my $ros1_12_convert = unpack('H*', "$ros1_12"); $ros1_12_convert =~ s{00}{}g;  
my $ros1_13_convert = unpack('H*', "$ros1_13"); $ros1_13_convert =~ s{00}{}g;  
my $ros1_14_convert = unpack('H*', "$ros1_14"); $ros1_14_convert =~ s{00}{}g;  
my $ros1_15_convert = unpack('H*', "$ros1_15"); $ros1_15_convert =~ s{00}{}g;  
my $ros1_16_convert = unpack('H*', "$ros1_16"); $ros1_16_convert =~ s{00}{}g;  
my $ros1_17_convert = unpack('H*', "$ros1_17"); $ros1_17_convert =~ s{00}{}g;  
my $ros1_18_convert = unpack('H*', "$ros1_18"); $ros1_18_convert =~ s{00}{}g;  
my $ros1_19_convert = unpack('H*', "$ros1_19"); $ros1_19_convert =~ s{00}{}g;  
my $ros1_20_convert = unpack('H*', "$ros1_20"); $ros1_20_convert =~ s{00}{}g;  
my $ros1_21_convert = unpack('H*', "$ros1_21"); $ros1_21_convert =~ s{00}{}g;  
my $ros1_22_convert = unpack('H*', "$ros1_22"); $ros1_22_convert =~ s{00||ff}{}g;  
my $ros1_23_convert = unpack('H*', "$ros1_23"); $ros1_23_convert =~ s{00||ff}{}g;  
my $ros1_24_convert = unpack('H*', "$ros1_24"); $ros1_24_convert =~ s{00||534345||ff}{}g;  
my $ros1_25_convert = unpack('H*', "$ros1_25"); $ros1_25_convert =~ s{00||ff}{}g;  

$ros1_1_pos = hex($ros1_1_pos); $ros1_1_pos = 8126480 + $ros1_1_pos; $ros1_1_len = hex($ros1_1_len);
seek($bin, $ros1_1_pos, 0);read($bin, my $ros1_1_file, $ros1_1_len); $ros1_1_file = uc md5_hex($ros1_1_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_1_file = "No_MD5_Availiable";}

$ros1_2_pos = hex($ros1_2_pos); $ros1_2_pos = 8126480 + $ros1_2_pos; $ros1_2_len = hex($ros1_2_len);
seek($bin, $ros1_2_pos, 0);read($bin, my $ros1_2_file, $ros1_2_len); $ros1_2_file = uc md5_hex($ros1_2_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_2_file = "No_MD5_Availiable";}

$ros1_3_pos = hex($ros1_3_pos); $ros1_3_pos = 8126480 + $ros1_3_pos; $ros1_3_len = hex($ros1_3_len);
seek($bin, $ros1_3_pos, 0);read($bin, my $ros1_3_file, $ros1_3_len); $ros1_3_file = uc md5_hex($ros1_3_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_3_file = "No_MD5_Availiable";}

$ros1_4_pos = hex($ros1_4_pos); $ros1_4_pos = 8126480 + $ros1_4_pos; $ros1_4_len = hex($ros1_4_len);
seek($bin, $ros1_4_pos, 0);read($bin, my $ros1_4_file, $ros1_4_len); $ros1_4_file = uc md5_hex($ros1_4_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_4_file = "No_MD5_Availiable";}

$ros1_5_pos = hex($ros1_5_pos); $ros1_5_pos = 8126480 + $ros1_5_pos; $ros1_5_len = hex($ros1_5_len);
seek($bin, $ros1_5_pos, 0);read($bin, my $ros1_5_file, $ros1_5_len); $ros1_5_file = uc md5_hex($ros1_5_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_5_file = "No_MD5_Availiable";}

$ros1_6_pos = hex($ros1_6_pos); $ros1_6_pos = 8126480 + $ros1_6_pos; $ros1_6_len = hex($ros1_6_len);
seek($bin, $ros1_6_pos, 0);read($bin, my $ros1_6_file, $ros1_6_len); $ros1_6_file = uc md5_hex($ros1_6_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_6_file = "No_MD5_Availiable";}

$ros1_7_pos = hex($ros1_7_pos); $ros1_7_pos = 8126480 + $ros1_7_pos; $ros1_7_len = hex($ros1_7_len);
seek($bin, $ros1_7_pos, 0);read($bin, my $ros1_7_file, $ros1_7_len); $ros1_7_file = uc md5_hex($ros1_7_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_7_file = "No_MD5_Availiable";}

$ros1_8_pos = hex($ros1_8_pos); $ros1_8_pos = 8126480 + $ros1_8_pos; $ros1_8_len = hex($ros1_8_len);
seek($bin, $ros1_8_pos, 0);read($bin, my $ros1_8_file, $ros1_8_len); $ros1_8_file = uc md5_hex($ros1_8_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_8_file = "No_MD5_Availiable";}

$ros1_9_pos = hex($ros1_9_pos); $ros1_9_pos = 8126480 + $ros1_9_pos; $ros1_9_len = hex($ros1_9_len);
seek($bin, $ros1_9_pos, 0);read($bin, my $ros1_9_file, $ros1_9_len); $ros1_9_file = uc md5_hex($ros1_9_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_9_file = "No_MD5_Availiable";}

$ros1_10_pos = hex($ros1_10_pos); $ros1_10_pos = 8126480 + $ros1_10_pos; $ros1_10_len = hex($ros1_10_len);
seek($bin, $ros1_10_pos, 0);read($bin, my $ros1_10_file, $ros1_10_len); $ros1_10_file = uc md5_hex($ros1_10_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_10_file = "No_MD5_Availiable";}

$ros1_11_pos = hex($ros1_11_pos); $ros1_11_pos = 8126480 + $ros1_11_pos; $ros1_11_len = hex($ros1_11_len);
seek($bin, $ros1_11_pos, 0);read($bin, my $ros1_11_file, $ros1_11_len); $ros1_11_file = uc md5_hex($ros1_11_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_11_file = "No_MD5_Availiable";}

$ros1_12_pos = hex($ros1_12_pos); $ros1_12_pos = 8126480 + $ros1_12_pos; $ros1_12_len = hex($ros1_12_len);
seek($bin, $ros1_12_pos, 0);read($bin, my $ros1_12_file, $ros1_12_len); $ros1_12_file = uc md5_hex($ros1_12_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_12_file = "No_MD5_Availiable";}

$ros1_13_pos = hex($ros1_13_pos); $ros1_13_pos = 8126480 + $ros1_13_pos; $ros1_13_len = hex($ros1_13_len);
seek($bin, $ros1_13_pos, 0);read($bin, my $ros1_13_file, $ros1_13_len); $ros1_13_file = uc md5_hex($ros1_13_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_13_file = "No_MD5_Availiable";}

$ros1_14_pos = hex($ros1_14_pos); $ros1_14_pos = 8126480 + $ros1_14_pos; $ros1_14_len = hex($ros1_14_len);
seek($bin, $ros1_14_pos, 0);read($bin, my $ros1_14_file, $ros1_14_len); $ros1_14_file = uc md5_hex($ros1_14_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_14_file = "No_MD5_Availiable";}

$ros1_15_pos = hex($ros1_15_pos); $ros1_15_pos = 8126480 + $ros1_15_pos; $ros1_15_len = hex($ros1_15_len);
seek($bin, $ros1_15_pos, 0);read($bin, my $ros1_15_file, $ros1_15_len); $ros1_15_file = uc md5_hex($ros1_15_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_15_file = "No_MD5_Availiable";}

$ros1_16_pos = hex($ros1_16_pos); $ros1_16_pos = 8126480 + $ros1_16_pos; $ros1_16_len = hex($ros1_16_len);
seek($bin, $ros1_16_pos, 0);read($bin, my $ros1_16_file, $ros1_16_len); $ros1_16_file = uc md5_hex($ros1_16_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_16_file = "No_MD5_Availiable";}

$ros1_17_pos = hex($ros1_17_pos); $ros1_17_pos = 8126480 + $ros1_17_pos; $ros1_17_len = hex($ros1_17_len);
seek($bin, $ros1_17_pos, 0);read($bin, my $ros1_17_file, $ros1_17_len); $ros1_17_file = uc md5_hex($ros1_17_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_17_file = "No_MD5_Availiable";}

$ros1_18_pos = hex($ros1_18_pos); $ros1_18_pos = 8126480 + $ros1_18_pos; $ros1_18_len = hex($ros1_18_len);
seek($bin, $ros1_18_pos, 0);read($bin, my $ros1_18_file, $ros1_18_len); $ros1_18_file = uc md5_hex($ros1_18_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_18_file = "No_MD5_Availiable";}

$ros1_19_pos = hex($ros1_19_pos); $ros1_19_pos = 8126480 + $ros1_19_pos; $ros1_19_len = hex($ros1_19_len);
seek($bin, $ros1_19_pos, 0);read($bin, my $ros1_19_file, $ros1_19_len); $ros1_19_file = uc md5_hex($ros1_19_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_19_file = "No_MD5_Availiable";}

$ros1_20_pos = hex($ros1_20_pos); $ros1_20_pos = 8126480 + $ros1_20_pos; $ros1_20_len = hex($ros1_20_len);
seek($bin, $ros1_20_pos, 0);read($bin, my $ros1_20_file, $ros1_20_len); $ros1_20_file = uc md5_hex($ros1_20_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_20_file = "No_MD5_Availiable";}

$ros1_21_pos = hex($ros1_21_pos); $ros1_21_pos = 8126480 + $ros1_21_pos; $ros1_21_len = hex($ros1_21_len);
seek($bin, $ros1_21_pos, 0);read($bin, my $ros1_21_file, $ros1_21_len); $ros1_21_file = uc md5_hex($ros1_21_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_21_file = "No_MD5_Availiable";}

$ros1_22_pos = hex($ros1_22_pos); $ros1_22_pos = 8126480 + $ros1_22_pos; $ros1_22_len = hex($ros1_22_len);
seek($bin, $ros1_22_pos, 0);read($bin, my $ros1_22_file, $ros1_22_len); $ros1_22_file = uc md5_hex($ros1_22_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_22_file = "No_MD5_Availiable";}

$ros1_23_pos = hex($ros1_23_pos); $ros1_23_pos = 8126480 + $ros1_23_pos; $ros1_23_len = hex($ros1_23_len);
seek($bin, $ros1_23_pos, 0);read($bin, my $ros1_23_file, $ros1_23_len); $ros1_23_file = uc md5_hex($ros1_23_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_23_file = "No_MD5_Availiable";}

$ros1_24_pos = hex($ros1_24_pos); $ros1_24_pos = 8126480 + $ros1_24_pos; $ros1_24_len = hex($ros1_24_len);
seek($bin, $ros1_24_pos, 0);read($bin, my $ros1_24_file, $ros1_24_len); $ros1_24_file = uc md5_hex($ros1_24_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_24_file = "No_MD5_Availiable";}

$ros1_25_pos = hex($ros1_25_pos); $ros1_25_pos = 8126480 + $ros1_25_pos; $ros1_25_len = hex($ros1_25_len);
seek($bin, $ros1_25_pos, 0);read($bin, my $ros1_25_file, $ros1_25_len); $ros1_25_file = uc md5_hex($ros1_25_file); if (exists $ros_filetable_versions{$es[0]} or exists $ros_filetable_versions{$es[1]}) {$ros1_25_file = "No_MD5_Availiable";}

my $ros1_1_authidpos = $ros1_1_pos + 112; seek($bin, $ros1_1_authidpos, 0);read($bin, my $ros1_1_authid, 0x8); $ros1_1_authid = uc ascii_to_hex($ros1_1_authid); if (exists $ros_not_self{$ros1_1_convert}) {$ros1_1_authid = "N/A"};
my $ros1_2_authidpos = $ros1_2_pos + 112; seek($bin, $ros1_2_authidpos, 0);read($bin, my $ros1_2_authid, 0x8); $ros1_2_authid = uc ascii_to_hex($ros1_2_authid); if (exists $ros_not_self{$ros1_2_convert}) {$ros1_2_authid = "N/A"};
my $ros1_3_authidpos = $ros1_3_pos + 112; seek($bin, $ros1_3_authidpos, 0);read($bin, my $ros1_3_authid, 0x8); $ros1_3_authid = uc ascii_to_hex($ros1_3_authid); if (exists $ros_not_self{$ros1_3_convert}) {$ros1_3_authid = "N/A"};
my $ros1_4_authidpos = $ros1_4_pos + 112; seek($bin, $ros1_4_authidpos, 0);read($bin, my $ros1_4_authid, 0x8); $ros1_4_authid = uc ascii_to_hex($ros1_4_authid); if (exists $ros_not_self{$ros1_4_convert}) {$ros1_4_authid = "N/A"};
my $ros1_5_authidpos = $ros1_5_pos + 112; seek($bin, $ros1_5_authidpos, 0);read($bin, my $ros1_5_authid, 0x8); $ros1_5_authid = uc ascii_to_hex($ros1_5_authid); if (exists $ros_not_self{$ros1_5_convert}) {$ros1_5_authid = "N/A"};
my $ros1_6_authidpos = $ros1_6_pos + 112; seek($bin, $ros1_6_authidpos, 0);read($bin, my $ros1_6_authid, 0x8); $ros1_6_authid = uc ascii_to_hex($ros1_6_authid); if (exists $ros_not_self{$ros1_6_convert}) {$ros1_6_authid = "N/A"};
my $ros1_7_authidpos = $ros1_7_pos + 112; seek($bin, $ros1_7_authidpos, 0);read($bin, my $ros1_7_authid, 0x8); $ros1_7_authid = uc ascii_to_hex($ros1_7_authid); if (exists $ros_not_self{$ros1_7_convert}) {$ros1_7_authid = "N/A"};
my $ros1_8_authidpos = $ros1_8_pos + 112; seek($bin, $ros1_8_authidpos, 0);read($bin, my $ros1_8_authid, 0x8); $ros1_8_authid = uc ascii_to_hex($ros1_8_authid); if (exists $ros_not_self{$ros1_8_convert}) {$ros1_8_authid = "N/A"};
my $ros1_9_authidpos = $ros1_9_pos + 112; seek($bin, $ros1_9_authidpos, 0);read($bin, my $ros1_9_authid, 0x8); $ros1_9_authid = uc ascii_to_hex($ros1_9_authid); if (exists $ros_not_self{$ros1_9_convert}) {$ros1_9_authid = "N/A"};
my $ros1_10_authidpos = $ros1_10_pos + 112; seek($bin, $ros1_10_authidpos, 0);read($bin, my $ros1_10_authid, 0x8); $ros1_10_authid = uc ascii_to_hex($ros1_10_authid); if (exists $ros_not_self{$ros1_10_convert}) {$ros1_10_authid = "N/A"};
my $ros1_11_authidpos = $ros1_11_pos + 112; seek($bin, $ros1_11_authidpos, 0);read($bin, my $ros1_11_authid, 0x8); $ros1_11_authid = uc ascii_to_hex($ros1_11_authid); if (exists $ros_not_self{$ros1_11_convert}) {$ros1_11_authid = "N/A"};
my $ros1_12_authidpos = $ros1_12_pos + 112; seek($bin, $ros1_12_authidpos, 0);read($bin, my $ros1_12_authid, 0x8); $ros1_12_authid = uc ascii_to_hex($ros1_12_authid); if (exists $ros_not_self{$ros1_12_convert}) {$ros1_12_authid = "N/A"};
my $ros1_13_authidpos = $ros1_13_pos + 112; seek($bin, $ros1_13_authidpos, 0);read($bin, my $ros1_13_authid, 0x8); $ros1_13_authid = uc ascii_to_hex($ros1_13_authid); if (exists $ros_not_self{$ros1_13_convert}) {$ros1_13_authid = "N/A"};
my $ros1_14_authidpos = $ros1_14_pos + 112; seek($bin, $ros1_14_authidpos, 0);read($bin, my $ros1_14_authid, 0x8); $ros1_14_authid = uc ascii_to_hex($ros1_14_authid); if (exists $ros_not_self{$ros1_14_convert}) {$ros1_14_authid = "N/A"};
my $ros1_15_authidpos = $ros1_15_pos + 112; seek($bin, $ros1_15_authidpos, 0);read($bin, my $ros1_15_authid, 0x8); $ros1_15_authid = uc ascii_to_hex($ros1_15_authid); if (exists $ros_not_self{$ros1_15_convert}) {$ros1_15_authid = "N/A"};
my $ros1_16_authidpos = $ros1_16_pos + 112; seek($bin, $ros1_16_authidpos, 0);read($bin, my $ros1_16_authid, 0x8); $ros1_16_authid = uc ascii_to_hex($ros1_16_authid); if (exists $ros_not_self{$ros1_16_convert}) {$ros1_16_authid = "N/A"};
my $ros1_17_authidpos = $ros1_17_pos + 112; seek($bin, $ros1_17_authidpos, 0);read($bin, my $ros1_17_authid, 0x8); $ros1_17_authid = uc ascii_to_hex($ros1_17_authid); if (exists $ros_not_self{$ros1_17_convert}) {$ros1_17_authid = "N/A"};
my $ros1_18_authidpos = $ros1_18_pos + 112; seek($bin, $ros1_18_authidpos, 0);read($bin, my $ros1_18_authid, 0x8); $ros1_18_authid = uc ascii_to_hex($ros1_18_authid); if (exists $ros_not_self{$ros1_18_convert}) {$ros1_18_authid = "N/A"};
my $ros1_19_authidpos = $ros1_19_pos + 112; seek($bin, $ros1_19_authidpos, 0);read($bin, my $ros1_19_authid, 0x8); $ros1_19_authid = uc ascii_to_hex($ros1_19_authid); if (exists $ros_not_self{$ros1_19_convert}) {$ros1_19_authid = "N/A"};
my $ros1_20_authidpos = $ros1_20_pos + 112; seek($bin, $ros1_20_authidpos, 0);read($bin, my $ros1_20_authid, 0x8); $ros1_20_authid = uc ascii_to_hex($ros1_20_authid); if (exists $ros_not_self{$ros1_20_convert}) {$ros1_20_authid = "N/A"};
my $ros1_21_authidpos = $ros1_21_pos + 112; seek($bin, $ros1_21_authidpos, 0);read($bin, my $ros1_21_authid, 0x8); $ros1_21_authid = uc ascii_to_hex($ros1_21_authid); if (exists $ros_not_self{$ros1_21_convert}) {$ros1_21_authid = "N/A"};
my $ros1_22_authidpos = $ros1_22_pos + 112; seek($bin, $ros1_22_authidpos, 0);read($bin, my $ros1_22_authid, 0x8); $ros1_22_authid = uc ascii_to_hex($ros1_22_authid); if (exists $ros_not_self{$ros1_22_convert}) {$ros1_22_authid = "N/A"};
my $ros1_23_authidpos = $ros1_23_pos + 112; seek($bin, $ros1_23_authidpos, 0);read($bin, my $ros1_23_authid, 0x8); $ros1_23_authid = uc ascii_to_hex($ros1_23_authid); if (exists $ros_not_self{$ros1_23_convert}) {$ros1_23_authid = "N/A"};
my $ros1_24_authidpos = $ros1_24_pos + 112; seek($bin, $ros1_24_authidpos, 0);read($bin, my $ros1_24_authid, 0x8); $ros1_24_authid = uc ascii_to_hex($ros1_24_authid); if (exists $ros_not_self{$ros1_24_convert}) {$ros1_24_authid = "N/A"};
my $ros1_25_authidpos = $ros1_25_pos + 112; seek($bin, $ros1_25_authidpos, 0);read($bin, my $ros1_25_authid, 0x8); $ros1_25_authid = uc ascii_to_hex($ros1_25_authid); if (exists $ros_not_self{$ros1_25_convert}) {$ros1_25_authid = "N/A"};

if ( $ros_list{$ros1_1_convert}) { print F "$ros_list{$ros1_1_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_1_convert}<br>";}
if ( $auth_id_list_nn{$ros1_1_authid}) { print F "AuthID: $ros1_1_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_1_authid<br>";}
if (exists $ros_md5_file{$ros1_1_file}) { print F "MD5: $ros1_1_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_1_file<br><br>";}
if ( $ros_list{$ros1_2_convert}) { print F "$ros_list{$ros1_2_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_2_convert}<br>";}
if ( $auth_id_list_nn{$ros1_2_authid}) { print F "AuthID: $ros1_2_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_2_authid<br>";}
if (exists $ros_md5_file{$ros1_2_file}) { print F "MD5: $ros1_2_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_2_file<br><br>";}
if ( $ros_list{$ros1_3_convert}) { print F "$ros_list{$ros1_3_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_3_convert}<br>";}
if ( $auth_id_list_nn{$ros1_3_authid}) { print F "AuthID: $ros1_3_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_3_authid<br>";}
if (exists $ros_md5_file{$ros1_3_file}) { print F "MD5: $ros1_3_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_3_file<br><br>";}
if ( $ros_list{$ros1_4_convert}) { print F "$ros_list{$ros1_4_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_4_convert}<br>";}
if ( $auth_id_list_nn{$ros1_4_authid}) { print F "AuthID: $ros1_4_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_4_authid<br>";}
if (exists $ros_md5_file{$ros1_4_file}) { print F "MD5: $ros1_4_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_4_file<br><br>";}
if ( $ros_list{$ros1_5_convert}) { print F "$ros_list{$ros1_5_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_5_convert}<br>";}
if ( $auth_id_list_nn{$ros1_5_authid}) { print F "AuthID: $ros1_5_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_5_authid<br>";}
if (exists $ros_md5_file{$ros1_5_file}) { print F "MD5: $ros1_5_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_5_file<br><br>";}
if ( $ros_list{$ros1_6_convert}) { print F "$ros_list{$ros1_6_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_6_convert}<br>";}
if ( $auth_id_list_nn{$ros1_6_authid}) { print F "AuthID: $ros1_6_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_6_authid<br>";}
if (exists $ros_md5_file{$ros1_6_file}) { print F "MD5: $ros1_6_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_6_file<br><br>";}
if ( $ros_list{$ros1_7_convert}) { print F "$ros_list{$ros1_7_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_7_convert}<br>";}
if ( $auth_id_list_nn{$ros1_7_authid}) { print F "AuthID: $ros1_7_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_7_authid<br>";}
if (exists $ros_md5_file{$ros1_7_file}) { print F "MD5: $ros1_7_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_7_file<br><br>";}
if ( $ros_list{$ros1_8_convert}) { print F "$ros_list{$ros1_8_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_8_convert}<br>";}
if ( $auth_id_list_nn{$ros1_8_authid}) { print F "AuthID: $ros1_8_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_8_authid<br>";}
if (exists $ros_md5_file{$ros1_8_file}) { print F "MD5: $ros1_8_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_8_file<br><br>";}
if ( $ros_list{$ros1_9_convert}) { print F "$ros_list{$ros1_9_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_9_convert}<br>";}
if ( $auth_id_list_nn{$ros1_9_authid}) { print F "AuthID: $ros1_9_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_9_authid<br>";}
if (exists $ros_md5_file{$ros1_9_file}) { print F "MD5: $ros1_9_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_9_file<br><br>";}
if ( $ros_list{$ros1_10_convert}) { print F "$ros_list{$ros1_10_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_10_convert}<br>";}
if ( $auth_id_list_nn{$ros1_10_authid}) { print F "AuthID: $ros1_10_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_10_authid<br>";}
if (exists $ros_md5_file{$ros1_10_file}) { print F "MD5: $ros1_10_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_10_file<br><br>";}
if ( $ros_list{$ros1_11_convert}) { print F "$ros_list{$ros1_11_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_11_convert}<br>";}
if ( $auth_id_list_nn{$ros1_11_authid}) { print F "AuthID: $ros1_11_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_11_authid<br>";}
if (exists $ros_md5_file{$ros1_11_file}) { print F "MD5: $ros1_11_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_11_file<br><br>";}
if ( $ros_list{$ros1_12_convert}) { print F "$ros_list{$ros1_12_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_12_convert}<br>";}
if ( $auth_id_list_nn{$ros1_12_authid}) { print F "AuthID: $ros1_12_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_12_authid<br>";}
if (exists $ros_md5_file{$ros1_12_file}) { print F "MD5: $ros1_12_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_12_file<br><br>";}
if ( $ros_list{$ros1_13_convert}) { print F "$ros_list{$ros1_13_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_13_convert}<br>";}
if ( $auth_id_list_nn{$ros1_13_authid}) { print F "AuthID: $ros1_13_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_13_authid<br>";}
if (exists $ros_md5_file{$ros1_13_file}) { print F "MD5: $ros1_13_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_13_file<br><br>";}
if ( $ros_list{$ros1_14_convert}) { print F "$ros_list{$ros1_14_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_14_convert}<br>";}
if ( $auth_id_list_nn{$ros1_14_authid}) { print F "AuthID: $ros1_14_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_14_authid<br>";}
if (exists $ros_md5_file{$ros1_14_file}) { print F "MD5: $ros1_14_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_14_file<br><br>";}
if ( $ros_list{$ros1_15_convert}) { print F "$ros_list{$ros1_15_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_15_convert}<br>";}
if ( $auth_id_list_nn{$ros1_15_authid}) { print F "AuthID: $ros1_15_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_15_authid<br>";}
if (exists $ros_md5_file{$ros1_15_file}) { print F "MD5: $ros1_15_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_15_file<br><br>";}
if ( $ros_list{$ros1_16_convert}) { print F "$ros_list{$ros1_16_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_16_convert}<br>";}
if ( $auth_id_list_nn{$ros1_16_authid}) { print F "AuthID: $ros1_16_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_16_authid<br>";}
if (exists $ros_md5_file{$ros1_16_file}) { print F "MD5: $ros1_16_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_16_file<br><br>";}
if ( $ros_list{$ros1_17_convert}) { print F "$ros_list{$ros1_17_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_17_convert}<br>";}
if ( $auth_id_list_nn{$ros1_17_authid}) { print F "AuthID: $ros1_17_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_17_authid<br>";}
if (exists $ros_md5_file{$ros1_17_file}) { print F "MD5: $ros1_17_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_17_file<br><br>";}
if ( $ros_list{$ros1_18_convert}) { print F "$ros_list{$ros1_18_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_18_convert}<br>";}
if ( $auth_id_list_nn{$ros1_18_authid}) { print F "AuthID: $ros1_18_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_18_authid<br>";}
if (exists $ros_md5_file{$ros1_18_file}) { print F "MD5: $ros1_18_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_18_file<br><br>";}
if ( $ros_list{$ros1_19_convert}) { print F "$ros_list{$ros1_19_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_19_convert}<br>";}
if ( $auth_id_list_nn{$ros1_19_authid}) { print F "AuthID: $ros1_19_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_19_authid<br>";}
if (exists $ros_md5_file{$ros1_19_file}) { print F "MD5: $ros1_19_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_19_file<br><br>";}
if ( $ros_list{$ros1_20_convert}) { print F "$ros_list{$ros1_20_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_20_convert}<br>";}
if ( $auth_id_list_nn{$ros1_20_authid}) { print F "AuthID: $ros1_20_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_20_authid<br>";}
if (exists $ros_md5_file{$ros1_20_file}) { print F "MD5: $ros1_20_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_20_file<br><br>";}
if ( $ros_list{$ros1_21_convert}) { print F "$ros_list{$ros1_21_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_21_convert}<br>";}
if ( $auth_id_list_nn{$ros1_21_authid}) { print F "AuthID: $ros1_21_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_21_authid<br>";}
if (exists $ros_md5_file{$ros1_21_file}) { print F "MD5: $ros1_21_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_21_file<br><br>";}
if ( $ros_list{$ros1_22_convert}) { print F "$ros_list{$ros1_22_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_22_convert}<br>";}
if ( $auth_id_list_nn{$ros1_22_authid}) { print F "AuthID: $ros1_22_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_22_authid<br>";}
if (exists $ros_md5_file{$ros1_22_file}) { print F "MD5: $ros1_22_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_22_file<br><br>";}

if ( $ros1_23_convert eq 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff' or ' ') {} else {
if ( $ros_list{$ros1_23_convert}) { print F "$ros_list{$ros1_23_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_23_convert}<br>";}
if ( $auth_id_list_nn{$ros1_23_authid}) { print F "AuthID: $ros1_23_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_23_authid<br>";}
if (exists $ros_md5_file{$ros1_23_file}) { print F "MD5: $ros1_23_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_23_file<br><br>";}
}

if ( $ros1_24_convert eq 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff' or ' ') {} else {
if ( $ros_list{$ros1_24_convert}) { print F "$ros_list{$ros1_24_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_24_convert}<br>";}
if ( $auth_id_list_nn{$ros1_24_authid}) { print F "AuthID: $ros1_24_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_24_authid<br>";}
if (exists $ros_md5_file{$ros1_24_file}) { print F "MD5: $ros1_24_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_24_file<br><br>";}
}

if ( $ros1_25_convert eq '063c980370' or 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff' or ' ') {} else {
if ( $ros_list{$ros1_25_convert}) { print F "$ros_list{$ros1_25_convert}", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $ros_list{$ros1_25_convert}<br>";}
if ( $auth_id_list_nn{$ros1_25_authid}) { print F "AuthID: $ros1_25_authid", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_25_authid<br>";}
if (exists $ros_md5_file{$ros1_25_file}) { print F "MD5: $ros1_25_file", $ok, "<br>"; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger- $ros1_25_file<br><br>";}
}

####################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################
print "\nMatching MD5's...\n\n"; 

##MAIN PART OF THIS CODE IS NOW IN THE PATCHING SECTION AT THE TOP!##

print F "<br><b>MD5 Validation:</b><br>";

print F "ROS0: "; if (exists $ros_md5_list{$ros0_convert}) { my $version = $ros_md5_list{$ros0_convert}; print F "$version - $ros0_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros0_convert - Patch & Recheck <br>";}
print F "ROS1: "; if (exists $ros_md5_list{$ros1_convert}) { my $version = $ros_md5_list{$ros1_convert}; print F "$version - $ros1_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ros1_convert - Patch & Recheck <br><br>";}
print F "TRVK_PRG0: "; if (exists $TRVK_PRG{$TRVK_PRG0}) { my $trvk_prg_version = $TRVK_PRG{$TRVK_PRG0}; print F "$trvk_prg_version - $TRVK_PRG0", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $TRVK_PRG0 - Patch & Recheck <br>";}
print F "TRVK_PRG1: "; if (exists $TRVK_PRG{$TRVK_PRG1}) { my $trvk_prg_version = $TRVK_PRG{$TRVK_PRG1}; print F "$trvk_prg_version - $TRVK_PRG1", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $TRVK_PRG1 - Patch & Recheck <br>";}
print F "TRVK_PKG0: "; if (exists $TRVK_PKG{$TRVK_PKG0}) { my $tvrk_pkg_version = $TRVK_PKG{$TRVK_PKG0}; print F "$tvrk_pkg_version - $TRVK_PKG0", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $TRVK_PKG0 - Patch & Recheck <br>";}
print F "TRVK_PKG1: "; if (exists $TRVK_PKG{$TRVK_PKG1}) { my $tvrk_pkg_version = $TRVK_PKG{$TRVK_PKG1}; print F "$tvrk_pkg_version - $TRVK_PKG1", $ok; push(@ok, "OK")} else { push(@warning, "WARNING"); print F "$warning - $TRVK_PKG1 - Patch & Recheck <br><br>";}


####################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################

####################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################
print "\nChecking CVTRM/VTRM0...\n\n"; 


seek($bin, 0xEC4030, 0);read($bin, my $cvtrm_vtrm_structure ,0x1060); $cvtrm_vtrm_structure = uc ascii_to_hex($cvtrm_vtrm_structure);

seek($bin, 0xEC50E0, 0);read($bin, my $cvtrm_1 ,0x10); $cvtrm_1 = uc ascii_to_hex($cvtrm_1);
seek($bin, 0xEC5140, 0);read($bin, my $cvtrm_2 ,0x10); $cvtrm_2 = uc ascii_to_hex($cvtrm_2);
seek($bin, 0xEC51A0, 0);read($bin, my $cvtrm_3 ,0x10); $cvtrm_3 = uc ascii_to_hex($cvtrm_3);
seek($bin, 0xEC5200, 0);read($bin, my $cvtrm_4 ,0x10); $cvtrm_4 = uc ascii_to_hex($cvtrm_4);
seek($bin, 0xEC5260, 0);read($bin, my $cvtrm_5 ,0x10); $cvtrm_5 = uc ascii_to_hex($cvtrm_5);
seek($bin, 0xEC52C0, 0);read($bin, my $cvtrm_6 ,0x10); $cvtrm_6 = uc ascii_to_hex($cvtrm_6);
seek($bin, 0xEC5320, 0);read($bin, my $cvtrm_7 ,0x10); $cvtrm_7 = uc ascii_to_hex($cvtrm_7);
seek($bin, 0xEC5380, 0);read($bin, my $cvtrm_8 ,0x10); $cvtrm_8 = uc ascii_to_hex($cvtrm_8);
seek($bin, 0xEC53E0, 0);read($bin, my $cvtrm_9 ,0x10); $cvtrm_9 = uc ascii_to_hex($cvtrm_9);
seek($bin, 0xEC5440, 0);read($bin, my $cvtrm_10 ,0x10); $cvtrm_10 = uc ascii_to_hex($cvtrm_10);
seek($bin, 0xEC54A0, 0);read($bin, my $cvtrm_11 ,0x10); $cvtrm_11 = uc ascii_to_hex($cvtrm_11);
seek($bin, 0xEC5500, 0);read($bin, my $cvtrm_12 ,0x10); $cvtrm_12 = uc ascii_to_hex($cvtrm_12); #00000FFFFF

seek($bin, 0xEC5090, 0);read($bin, my $cvtrm_static1 ,0x08);  $cvtrm_static1 = uc ascii_to_hex($cvtrm_static1);#static
seek($bin, 0xEC5098, 0);read($bin, my $cvtrm_static2 ,0x08);  $cvtrm_static2 = uc ascii_to_hex($cvtrm_static2);#semi static - regex
seek($bin, 0xEC50F8, 0);read($bin, my $cvtrm_static2b ,0x08);  $cvtrm_static2b = uc ascii_to_hex($cvtrm_static2b);#semi static - regex
seek($bin, 0xEC51F0, 0);read($bin, my $cvtrm_static3 ,0x08);  $cvtrm_static3 = uc ascii_to_hex($cvtrm_static3);#
seek($bin, 0xEC51F8, 0);read($bin, my $cvtrm_static4 ,0x08);  $cvtrm_static4 = uc ascii_to_hex($cvtrm_static4);#
seek($bin, 0xEC5150, 0);read($bin, my $cvtrm_static5 ,0x08);  $cvtrm_static5 = uc ascii_to_hex($cvtrm_static5);#if FF change footer/header
seek($bin, 0xEC51B0, 0);read($bin, my $cvtrm_static6 ,0x08);  $cvtrm_static6 = uc ascii_to_hex($cvtrm_static6);#if FF change footer/header
seek($bin, 0xEC51B8, 0);read($bin, my $cvtrm_static7 ,0x08);  $cvtrm_static7 = uc ascii_to_hex($cvtrm_static7);#if FF change footer/header
seek($bin, 0xEC5210, 0);read($bin, my $cvtrm_static8 ,0x08); $cvtrm_static8 = uc ascii_to_hex($cvtrm_static8);
seek($bin, 0xEC5218, 0);read($bin, my $cvtrm_static9 ,0x08); $cvtrm_static9 = uc ascii_to_hex($cvtrm_static9);
seek($bin, 0xEC5270, 0);read($bin, my $cvtrm_static10 ,0x08); $cvtrm_static10 = uc ascii_to_hex($cvtrm_static10);
seek($bin, 0xEC5278, 0);read($bin, my $cvtrm_static11 ,0x08); $cvtrm_static11 = uc ascii_to_hex($cvtrm_static11);
seek($bin, 0xEC52D0, 0);read($bin, my $cvtrm_static12 ,0x08); $cvtrm_static12 = uc ascii_to_hex($cvtrm_static12);
seek($bin, 0xEC52D8, 0);read($bin, my $cvtrm_static13 ,0x08); $cvtrm_static13 = uc ascii_to_hex($cvtrm_static13);
seek($bin, 0xEC5330, 0);read($bin, my $cvtrm_static14 ,0x08); $cvtrm_static14 = uc ascii_to_hex($cvtrm_static14);
seek($bin, 0xEC5338, 0);read($bin, my $cvtrm_static15 ,0x08); $cvtrm_static15 = uc ascii_to_hex($cvtrm_static15);
seek($bin, 0xEC5390, 0);read($bin, my $cvtrm_static16 ,0x08); $cvtrm_static16 = uc ascii_to_hex($cvtrm_static16);
seek($bin, 0xEC5398, 0);read($bin, my $cvtrm_static17 ,0x08); $cvtrm_static17 = uc ascii_to_hex($cvtrm_static17);
seek($bin, 0xEC53F0, 0);read($bin, my $cvtrm_static18 ,0x08); $cvtrm_static18 = uc ascii_to_hex($cvtrm_static18);
seek($bin, 0xEC53F8, 0);read($bin, my $cvtrm_static19 ,0x08); $cvtrm_static19 = uc ascii_to_hex($cvtrm_static19);
seek($bin, 0xEC5450, 0);read($bin, my $cvtrm_static20 ,0x08); $cvtrm_static20 = uc ascii_to_hex($cvtrm_static20);
seek($bin, 0xEC5458, 0);read($bin, my $cvtrm_static21 ,0x08); $cvtrm_static21 = uc ascii_to_hex($cvtrm_static21);
seek($bin, 0xEC54B0, 0);read($bin, my $cvtrm_static22 ,0x08); $cvtrm_static22 = uc ascii_to_hex($cvtrm_static22);
seek($bin, 0xEC54B8, 0);read($bin, my $cvtrm_static23 ,0x08); $cvtrm_static23 = uc ascii_to_hex($cvtrm_static23);

seek($bin, 0xEC52D0, 0);read($bin, my $cvtrm_unknown_filler ,0x018470); $cvtrm_unknown_filler = uc ascii_to_hex($cvtrm_unknown_filler);
seek($bin, 0xEC5330, 0);read($bin, my $cvtrm_unknown_filler_2 ,0x018401); $cvtrm_unknown_filler_2 = uc ascii_to_hex($cvtrm_unknown_filler_2);


seek($bin, 0xEDE6E8, 0);read($bin, my $cvtrm_sequence2,0x1914); $cvtrm_sequence2 = uc ascii_to_hex($cvtrm_sequence2);
seek($bin, 0xEE0000, 0);read($bin, my $cvtrm_unknown_footer ,0x10); $cvtrm_unknown_footer = uc ascii_to_hex($cvtrm_unknown_footer);
seek($bin, 0xEE0010, 0);read($bin, my $cvtrm_unknown_filler2 ,0x3FF0); $cvtrm_unknown_filler2 = uc ascii_to_hex($cvtrm_unknown_filler2);

seek($bin, 0xEE4000, 0);read($bin, my $cvtrm_vtrm2 ,0x10); $cvtrm_vtrm2 = uc ascii_to_hex($cvtrm_vtrm2);
seek($bin, 0xEE4030, 0);read($bin, my $cvtrm_vtrm2_structure ,0x1060); $cvtrm_vtrm2_structure = uc ascii_to_hex($cvtrm_vtrm2_structure);


#######################
#CVTRM
seek($bin, 0xEC0000, 0);read($bin, my $cvtrm_header ,0x04); 
seek($bin, 0xEC0004, 0);read($bin, my $cvtrm_filler ,0x0C); $cvtrm_filler = uc ascii_to_hex($cvtrm_filler);
seek($bin, 0xEC0010, 0);read($bin, my $cvtrm_structure ,0x3FF0); $cvtrm_structure = uc ascii_to_hex($cvtrm_structure);
#VTRM 0
seek($bin, 0xEC4000, 0);read($bin, my $cvtrm_vtrm0 ,0x10); $cvtrm_vtrm0 = uc ascii_to_hex($cvtrm_vtrm0);
seek($bin, 0xEC4010, 0);read($bin, my $cvtrm_vtrm0_sha1 ,0x14); $cvtrm_vtrm0_sha1 = uc ascii_to_hex($cvtrm_vtrm0_sha1);
seek($bin, 0xEC4024, 0);read($bin, my $cvtrm_vtrm0_unknown ,0x04); $cvtrm_vtrm0_unknown = uc ascii_to_hex($cvtrm_vtrm0_unknown);
seek($bin, 0xEC4028, 0);read($bin, my $cvtrm_vtrm0_rentries ,0x08); $cvtrm_vtrm0_rentries = uc ascii_to_hex($cvtrm_vtrm0_rentries);
seek($bin, 0xEC4030, 0);read($bin, my $cvtrm_vtrm0_ftrentries ,0x08); $cvtrm_vtrm0_ftrentries = uc ascii_to_hex($cvtrm_vtrm0_ftrentries);
seek($bin, 0xEC4038, 0);read($bin, my $cvtrm_vtrm0_ftuentries ,0x08); $cvtrm_vtrm0_ftuentries = uc ascii_to_hex($cvtrm_vtrm0_ftuentries);
seek($bin, 0xEC4040, 0);read($bin, my $cvtrm_vtrm0_ftentries ,0x1050); $cvtrm_vtrm0_ftentries = uc ascii_to_hex($cvtrm_vtrm0_ftentries);
$cvtrm_vtrm0_rentries = hex($cvtrm_vtrm0_rentries); $cvtrm_vtrm0_ftuentries = hex($cvtrm_vtrm0_ftuentries); $cvtrm_vtrm0_ftrentries = hex($cvtrm_vtrm0_ftrentries);

#VTRM0SELFDATA

### self block one
seek($bin, 0xEC5088, 0);read($bin, my $cvtrm_tableentry_1 ,0x08);  $cvtrm_tableentry_1 = uc ascii_to_hex($cvtrm_tableentry_1); #920/self
seek($bin, 0xEC5090, 0);read($bin, my $cvtrm_tablerentries_1 ,0x08);  $cvtrm_tablerentries_1 = uc ascii_to_hex($cvtrm_tablerentries_1); #self/unknown
seek($bin, 0xEC5098, 0);read($bin, my $cvtrm_selfid_1 ,0x08);  $cvtrm_selfid_1 = uc ascii_to_hex($cvtrm_selfid_1); #self
seek($bin, 0xEC50A0, 0);read($bin, my $cvtrm_1 ,0x48); $cvtrm_1 = uc ascii_to_hex($cvtrm_1); #selfdata

### self block two
seek($bin, 0xEC50E8, 0);read($bin, my $cvtrm_tableentry_2 ,0x08);  $cvtrm_tableentry_2 = uc ascii_to_hex($cvtrm_tableentry_2); #920
seek($bin, 0xEC50F0, 0);read($bin, my $cvtrm_tablerentries_2 ,0x08);  $cvtrm_tablerentries_2 = uc ascii_to_hex($cvtrm_tablerentries_2); #self/unknown
seek($bin, 0xEC50F8, 0);read($bin, my $cvtrm_selfid_2 ,0x08);  $cvtrm_selfid_2 = uc ascii_to_hex($cvtrm_selfid_2); #self
seek($bin, 0xEC5100, 0);read($bin, my $cvtrm_2 ,0x48); $cvtrm_2 = uc ascii_to_hex($cvtrm_2); #selfdata

### self block three
seek($bin, 0xEC5148, 0);read($bin, my $cvtrm_tableentry_3 ,0x08);  $cvtrm_tableentry_3 = uc ascii_to_hex($cvtrm_tableentry_3); #920
seek($bin, 0xEC5150, 0);read($bin, my $cvtrm_tablerentries_3 ,0x08);  $cvtrm_tablerentries_3 = uc ascii_to_hex($cvtrm_tablerentries_3); #self/unknown
seek($bin, 0xEC5158, 0);read($bin, my $cvtrm_selfid_3 ,0x08);  $cvtrm_selfid_3 = uc ascii_to_hex($cvtrm_selfid_3); #self
seek($bin, 0xEC5160, 0);read($bin, my $cvtrm_3 ,0x48); $cvtrm_3 = uc ascii_to_hex($cvtrm_3); #selfdata

### self block four
seek($bin, 0xEC51A8, 0);read($bin, my $cvtrm_tableentry_4 ,0x08);  $cvtrm_tableentry_4 = uc ascii_to_hex($cvtrm_tableentry_4); #920
seek($bin, 0xEC51B0, 0);read($bin, my $cvtrm_tablerentries_4 ,0x08);  $cvtrm_tablerentries_4 = uc ascii_to_hex($cvtrm_tablerentries_4); #self/unknown
seek($bin, 0xEC51B8, 0);read($bin, my $cvtrm_selfid_4 ,0x08);  $cvtrm_selfid_4 = uc ascii_to_hex($cvtrm_selfid_4); #self
seek($bin, 0xEC51C0, 0);read($bin, my $cvtrm_4 ,0x48); $cvtrm_4 = uc ascii_to_hex($cvtrm_4); #selfdata

### self block five
seek($bin, 0xEC5208, 0);read($bin, my $cvtrm_tableentry_5 ,0x08);  $cvtrm_tableentry_5 = uc ascii_to_hex($cvtrm_tableentry_5); #920
seek($bin, 0xEC5210, 0);read($bin, my $cvtrm_tablerentries_5 ,0x08);  $cvtrm_tablerentries_5 = uc ascii_to_hex($cvtrm_tablerentries_5); #self/unknown
seek($bin, 0xEC5218, 0);read($bin, my $cvtrm_selfid_5 ,0x08);  $cvtrm_selfid_5 = uc ascii_to_hex($cvtrm_selfid_5); #self
seek($bin, 0xEC5220, 0);read($bin, my $cvtrm_5 ,0x48); $cvtrm_5 = uc ascii_to_hex($cvtrm_5); #selfdata

### self block six
seek($bin, 0xEC5268, 0);read($bin, my $cvtrm_tableentry_6 ,0x08);  $cvtrm_tableentry_6 = uc ascii_to_hex($cvtrm_tableentry_6); #920
seek($bin, 0xEC5270, 0);read($bin, my $cvtrm_tablerentries_6 ,0x08);  $cvtrm_tablerentries_6 = uc ascii_to_hex($cvtrm_tablerentries_6); #self/unknown
seek($bin, 0xEC5278, 0);read($bin, my $cvtrm_selfid_6 ,0x08);  $cvtrm_selfid_6 = uc ascii_to_hex($cvtrm_selfid_6); #self
seek($bin, 0xEC5280, 0);read($bin, my $cvtrm_6 ,0x48); $cvtrm_6 = uc ascii_to_hex($cvtrm_6); #selfdata

### self block seven
seek($bin, 0xEC52C8, 0);read($bin, my $cvtrm_tableentry_7 ,0x08);  $cvtrm_tableentry_7 = uc ascii_to_hex($cvtrm_tableentry_7); #920
seek($bin, 0xEC52D0, 0);read($bin, my $cvtrm_tablerentries_7 ,0x08);  $cvtrm_tablerentries_7 = uc ascii_to_hex($cvtrm_tablerentries_7); #self/unknown
seek($bin, 0xEC52D8, 0);read($bin, my $cvtrm_selfid_7 ,0x08);  $cvtrm_selfid_7 = uc ascii_to_hex($cvtrm_selfid_7); #self
seek($bin, 0xEC52E0, 0);read($bin, my $cvtrm_7 ,0x48); $cvtrm_7 = uc ascii_to_hex($cvtrm_7); #selfdata

### self block eight
seek($bin, 0xEC5328, 0);read($bin, my $cvtrm_tableentry_8 ,0x08);  $cvtrm_tableentry_8 = uc ascii_to_hex($cvtrm_tableentry_8); #920
seek($bin, 0xEC5330, 0);read($bin, my $cvtrm_tablerentries_8 ,0x08);  $cvtrm_tablerentries_8 = uc ascii_to_hex($cvtrm_tablerentries_8); #self/unknown
seek($bin, 0xEC5338, 0);read($bin, my $cvtrm_selfid_8 ,0x08);  $cvtrm_selfid_8 = uc ascii_to_hex($cvtrm_selfid_8); #self
seek($bin, 0xEC5340, 0);read($bin, my $cvtrm_8 ,0x48); $cvtrm_8 = uc ascii_to_hex($cvtrm_8); #selfdata

### self block nine
seek($bin, 0xEC5388, 0);read($bin, my $cvtrm_tableentry_9 ,0x08);  $cvtrm_tableentry_9 = uc ascii_to_hex($cvtrm_tableentry_9); #920
seek($bin, 0xEC5390, 0);read($bin, my $cvtrm_tablerentries_9 ,0x08);  $cvtrm_tablerentries_9 = uc ascii_to_hex($cvtrm_tablerentries_9); #self/unknown
seek($bin, 0xEC5398, 0);read($bin, my $cvtrm_selfid_9 ,0x08);  $cvtrm_selfid_9 = uc ascii_to_hex($cvtrm_selfid_9); #self
seek($bin, 0xEC53A0, 0);read($bin, my $cvtrm_9 ,0x48); $cvtrm_9 = uc ascii_to_hex($cvtrm_9); #selfdata

### self block ten
seek($bin, 0xEC53E8, 0);read($bin, my $cvtrm_tableentry_10 ,0x08);  $cvtrm_tableentry_10 = uc ascii_to_hex($cvtrm_tableentry_10); #920
seek($bin, 0xEC53F0, 0);read($bin, my $cvtrm_tablerentries_10 ,0x08);  $cvtrm_tablerentries_10 = uc ascii_to_hex($cvtrm_tablerentries_10); #self/unknown
seek($bin, 0xEC53F8, 0);read($bin, my $cvtrm_selfid_10 ,0x08);  $cvtrm_selfid_10 = uc ascii_to_hex($cvtrm_selfid_10); #self
seek($bin, 0xEC5400, 0);read($bin, my $cvtrm_10 ,0x48); $cvtrm_10 = uc ascii_to_hex($cvtrm_10); #selfdata

### self block eleven
seek($bin, 0xEC5448, 0);read($bin, my $cvtrm_tableentry_11 ,0x08);  $cvtrm_tableentry_11 = uc ascii_to_hex($cvtrm_tableentry_11); #920
seek($bin, 0xEC5450, 0);read($bin, my $cvtrm_tablerentries_11 ,0x08);  $cvtrm_tablerentries_11 = uc ascii_to_hex($cvtrm_tablerentries_11); #self/unknown
seek($bin, 0xEC5458, 0);read($bin, my $cvtrm_selfid_11 ,0x08);  $cvtrm_selfid_11 = uc ascii_to_hex($cvtrm_selfid_11); #self
seek($bin, 0xEC5460, 0);read($bin, my $cvtrm_11 ,0x48); $cvtrm_11 = uc ascii_to_hex($cvtrm_11); #selfdata

### self block twelve
seek($bin, 0xEC54A8, 0);read($bin, my $cvtrm_tableentry_12 ,0x08);  $cvtrm_tableentry_12 = uc ascii_to_hex($cvtrm_tableentry_12); #920
seek($bin, 0xEC54B0, 0);read($bin, my $cvtrm_tablerentries_12 ,0x08);  $cvtrm_tablerentries_12 = uc ascii_to_hex($cvtrm_tablerentries_12); #self/unknown
seek($bin, 0xEC54B8, 0);read($bin, my $cvtrm_selfid_12 ,0x08);  $cvtrm_selfid_12 = uc ascii_to_hex($cvtrm_selfid_12); #self
seek($bin, 0xEC54C0, 0);read($bin, my $cvtrm_12 ,0x48); $cvtrm_12 = uc ascii_to_hex($cvtrm_12); #selfdata

#VTRM 0 Continued

seek($bin, 0xEDD748, 0);read($bin, my $cvtrm_vtrm0_sequence_key,0x14); $cvtrm_vtrm0_sequence_key = uc ascii_to_hex($cvtrm_vtrm0_sequence_key);
seek($bin, 0xEDD748, 0);read($bin, my $cvtrm_vtrm0_sequence,0x0F8C); $cvtrm_vtrm0_sequence = uc ascii_to_hex($cvtrm_vtrm0_sequence);

################################
print F "<br><b>CVTRM 0:</b><br>";

print F "Header - "; if ($cvtrm_header eq "SCEI" or "VTRM" or "....") { print F $cvtrm_header, $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm_header<br>";}
print F "Filler -"; if ($cvtrm_filler eq "FFFDFFFFFFFFFFFFFFFFFFFF" or "FFFFFFFFFFFFFFFFFFFFFFFF") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_filler<br>";}
print F "Filled Space -"; if ($cvtrm_structure =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}

print F "<br><b>VTRM 0:</b><br>";

print F "Header - "; if ($cvtrm_vtrm0 eq "000000005654524D0000000000000004" ) { print F "VTRM", $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_vtrm0<br>";}
print F "SHA1 Hash - "; if ($cvtrm_vtrm0_sha1 =~ m![^FF]*$!) { print F "$cvtrm_vtrm0_sha1", $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - $cvtrm_vtrm0_sha1<br>";}
print F "Padding - "; if ($cvtrm_vtrm0_unknown eq "000000E0" or "00000000") { print F "$cvtrm_vtrm0_unknown", $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - $cvtrm_vtrm0_unknown<br>";}
print F "X & Y Tables Reserved Entries - "; if ($cvtrm_vtrm0_rentries =~ m!^[0-9]*$!) { print F $cvtrm_vtrm0_rentries, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_vtrm0_rentries<br>";}
print F "Protected Files Table Reserved Entries - "; if ($cvtrm_vtrm0_ftrentries =~ m!^[0-9]*$!) { print F $cvtrm_vtrm0_ftrentries, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_vtrm0_ftrentries<br>";}
print F "Protected Files Table Used Entries - "; if ($cvtrm_vtrm0_ftuentries =~ m!^[0-9]*$!) { print F $cvtrm_vtrm0_ftuentries, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_vtrm0_ftuentries<br>";}
print F "Reserved Entries -"; if ($cvtrm_vtrm0_ftentries =~ m!^[0000000000000][00A|00B|412][0-9A-Z]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - Too long to display!<br>";}


print F "<br><b>VTRM 0 Table Entries:</b><br>"; 

if ($cvtrm_vtrm0_ftuentries >= 1) {
print F "Table Entry 1 - "; if ($cvtrm_tableentry_1 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tableentry_1<br>";}
print F "Reserved Table Entry 1 - "; if (exists $auth_id_list{$cvtrm_tablerentries_1}){ my $cvtrm_rentries_1_result = $auth_id_list{$cvtrm_tablerentries_1}; print F "$cvtrm_tablerentries_1 - $cvtrm_rentries_1_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm_tablerentries_1 =~ m!^[0-9]*$!) { print F $cvtrm_tablerentries_1, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_1<br>";}
print F "Used Table Entry 1 - "; if (exists $auth_id_list{$cvtrm_selfid_1}) { my $cvtrm_selfid_1_result = $auth_id_list{$cvtrm_selfid_1}; print F "$cvtrm_selfid_1 - $cvtrm_selfid_1_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm_selfid_1<br>";}
print F "Self Data Validation - "; if ($cvtrm_1 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_1<br>";} else { print F $ok; push(@ok, "OK");}
}

if ($cvtrm_vtrm0_ftuentries >= 2) {
print F "<br>Table Entry 2 - "; if ($cvtrm_tableentry_2 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tableentry_2<br>";}
print F "Reserved Table Entry 2 - "; if (exists $auth_id_list{$cvtrm_tablerentries_2}){ my $cvtrm_rentries_2_result = $auth_id_list{$cvtrm_tablerentries_2}; print F "$cvtrm_tablerentries_2 - $cvtrm_rentries_2_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm_tablerentries_2 =~ m!^[0-9]*$!) { print F $cvtrm_tablerentries_2, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_2<br>";}
print F "Used Table Entry 2 - "; if (exists $auth_id_list{$cvtrm_selfid_2}) { my $cvtrm_selfid_2_result = $auth_id_list{$cvtrm_selfid_2}; print F "$cvtrm_selfid_2 - $cvtrm_selfid_2_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm_selfid_2<br>";}
print F "Self Data Validation - "; if ($cvtrm_2 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_2<br>";} else { print F $ok; push(@ok, "OK");}
} 

if ($cvtrm_vtrm0_ftuentries >= 3) {
print F "<br>Table Entry 3 - "; if ($cvtrm_tableentry_3 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tableentry_3<br>";}
print F "Reserved Table Entry 3 - "; if (exists $auth_id_list{$cvtrm_tablerentries_3}){ my $cvtrm_rentries_3_result = $auth_id_list{$cvtrm_tablerentries_3}; print F "$cvtrm_tablerentries_3 - $cvtrm_rentries_3_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm_tablerentries_3 =~ m!^[0-9]*$!) { print F $cvtrm_tablerentries_3, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_3<br>";}
print F "Used Table Entry 3 - "; if (exists $auth_id_list{$cvtrm_selfid_3}) { my $cvtrm_selfid_3_result = $auth_id_list{$cvtrm_selfid_3}; print F "$cvtrm_selfid_3 - $cvtrm_selfid_3_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm_selfid_3<br>";}
print F "Self Data Validation - "; if ($cvtrm_3 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_3<br>";} else { print F $ok; push(@ok, "OK");}
} 

if ($cvtrm_vtrm0_ftuentries >= 4) {
print F "<br>Table Entry 4 - "; if ($cvtrm_tableentry_4 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tableentry_4<br>";}
print F "Reserved Table Entry 4 - "; if (exists $auth_id_list{$cvtrm_tablerentries_4}){ my $cvtrm_rentries_4_result = $auth_id_list{$cvtrm_tablerentries_4}; print F "$cvtrm_tablerentries_4 - $cvtrm_rentries_4_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm_tablerentries_4 =~ m!^[0-9]*$!) { print F $cvtrm_tablerentries_4, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_4<br>";}
print F "Used Table Entry 4 - "; if (exists $auth_id_list{$cvtrm_selfid_4}) { my $cvtrm_selfid_4_result = $auth_id_list{$cvtrm_selfid_4}; print F "$cvtrm_selfid_4 - $cvtrm_selfid_4_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm_selfid_4<br>";}
print F "Self Data Validation - "; if ($cvtrm_4 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_4<br>";} else { print F $ok; push(@ok, "OK");}
} 

if ($cvtrm_vtrm0_ftuentries >= 5) {
print F "<br>Table Entry 5 - "; if ($cvtrm_tableentry_5 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tableentry_5<br>";}
print F "Reserved Table Entry 5 - "; if (exists $auth_id_list{$cvtrm_tablerentries_5}){ my $cvtrm_rentries_5_result = $auth_id_list{$cvtrm_tablerentries_5}; print F "$cvtrm_tablerentries_5 - $cvtrm_rentries_5_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm_tablerentries_5 =~ m!^[0-9]*$!) { print F $cvtrm_tablerentries_5, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_5<br>";}
print F "Used Table Entry 5 - "; if (exists $auth_id_list{$cvtrm_selfid_5}) { my $cvtrm_selfid_5_result = $auth_id_list{$cvtrm_selfid_5}; print F "$cvtrm_selfid_5 - $cvtrm_selfid_5_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm_selfid_5<br>";}
print F "Self Data Validation - "; if ($cvtrm_5 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_5<br>";} else { print F $ok; push(@ok, "OK");}
} 

if ($cvtrm_vtrm0_ftuentries >= 6) {
print F "<br>Table Entry 6 - "; if ($cvtrm_tableentry_6 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tableentry_6<br>";}
print F "Reserved Table Entry 6 - "; if (exists $auth_id_list{$cvtrm_tablerentries_6}){ my $cvtrm_rentries_6_result = $auth_id_list{$cvtrm_tablerentries_6}; print F "$cvtrm_tablerentries_6 - $cvtrm_rentries_6_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm_tablerentries_6 =~ m!^[0-9]*$!) { print F $cvtrm_tablerentries_6, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_6<br>";}
print F "Used Table Entry 6 - "; if (exists $auth_id_list{$cvtrm_selfid_6}) { my $cvtrm_selfid_6_result = $auth_id_list{$cvtrm_selfid_6}; print F "$cvtrm_selfid_6 - $cvtrm_selfid_6_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm_selfid_6<br>";}
print F "Self Data Validation - "; if ($cvtrm_6 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_6<br>";} else { print F $ok; push(@ok, "OK");}
} 

if ($cvtrm_vtrm0_ftuentries >= 7) {
print F "<br>Table Entry 7 - "; if ($cvtrm_tableentry_7 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tableentry_7<br>";}
print F "Reserved Table Entry 7 - "; if (exists $auth_id_list{$cvtrm_tablerentries_7}){ my $cvtrm_rentries_7_result = $auth_id_list{$cvtrm_tablerentries_7}; print F "$cvtrm_tablerentries_7 - $cvtrm_rentries_7_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm_tablerentries_7 =~ m!^[0-9]*$!) { print F $cvtrm_tablerentries_7, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_7<br>";}
print F "Used Table Entry 7 - "; if (exists $auth_id_list{$cvtrm_selfid_7}) { my $cvtrm_selfid_7_result = $auth_id_list{$cvtrm_selfid_7}; print F "$cvtrm_selfid_7 - $cvtrm_selfid_7_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm_selfid_7<br>";}
print F "Self Data Validation - "; if ($cvtrm_7 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_7<br>";} else { print F $ok; push(@ok, "OK");}
} 

if ($cvtrm_vtrm0_ftuentries >= 8) {
print F "<br>Table Entry 8 - "; if ($cvtrm_tableentry_8 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tableentry_8<br>";}
print F "Reserved Table Entry 8 - "; if (exists $auth_id_list{$cvtrm_tablerentries_8}){ my $cvtrm_rentries_8_result = $auth_id_list{$cvtrm_tablerentries_8}; print F "$cvtrm_tablerentries_8 - $cvtrm_rentries_8_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm_tablerentries_8 =~ m!^[0-9]*$!) { print F $cvtrm_tablerentries_8, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_8<br>";}
print F "Used Table Entry 8 - "; if (exists $auth_id_list{$cvtrm_selfid_8}) { my $cvtrm_selfid_8_result = $auth_id_list{$cvtrm_selfid_8}; print F "$cvtrm_selfid_8 - $cvtrm_selfid_8_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm_selfid_8<br>";}
print F "Self Data Validation - "; if ($cvtrm_8 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_8<br>";} else { print F $ok; push(@ok, "OK");}
}

if ($cvtrm_vtrm0_ftuentries >= 9) {
print F "<br>Table Entry 9 - "; if ($cvtrm_tableentry_9 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tableentry_9<br>";}
print F "Reserved Table Entry 9 - "; if (exists $auth_id_list{$cvtrm_tablerentries_9}){ my $cvtrm_rentries_9_result = $auth_id_list{$cvtrm_tablerentries_9}; print F "$cvtrm_tablerentries_9 - $cvtrm_rentries_9_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm_tablerentries_9 =~ m!^[0-9]*$!) { print F $cvtrm_tablerentries_9, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_9<br>";}
print F "Used Table Entry 9 - "; if (exists $auth_id_list{$cvtrm_selfid_9}) { my $cvtrm_selfid_9_result = $auth_id_list{$cvtrm_selfid_9}; print F "$cvtrm_selfid_9 - $cvtrm_selfid_9_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm_selfid_9<br>";}
print F "Self Data Validation - "; if ($cvtrm_9 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_9<br>";} else { print F $ok; push(@ok, "OK");}
} 
if ($cvtrm_vtrm0_ftuentries >= 10) {
print F "<br>Table Entry 10 - "; if ($cvtrm_tableentry_10 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tableentry_10<br>";}
print F "Reserved Table Entry 10 - "; if (exists $auth_id_list{$cvtrm_tablerentries_10}){ my $cvtrm_rentries_10_result = $auth_id_list{$cvtrm_tablerentries_10}; print F "$cvtrm_tablerentries_10 - $cvtrm_rentries_10_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm_tablerentries_10 =~ m!^[0-9]*$!) { print F $cvtrm_tablerentries_10, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_10<br>";}
print F "Used Table Entry 10 - "; if (exists $auth_id_list{$cvtrm_selfid_10}) { my $cvtrm_selfid_10_result = $auth_id_list{$cvtrm_selfid_10}; print F "$cvtrm_selfid_10 - $cvtrm_selfid_10_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm_selfid_10<br>";}
print F "Self Data Validation - "; if ($cvtrm_10 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_10<br>";} else { print F $ok; push(@ok, "OK");}
}

if ($cvtrm_vtrm0_ftuentries >= 11) {
print F "<br>Table Entry 11 - "; if ($cvtrm_tableentry_11 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tableentry_11<br>";}
print F "Reserved Table Entry 11 - "; if (exists $auth_id_list{$cvtrm_tablerentries_11}){ my $cvtrm_rentries_11_result = $auth_id_list{$cvtrm_tablerentries_11}; print F "$cvtrm_tablerentries_11 - $cvtrm_rentries_11_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm_tablerentries_11 =~ m!^[0-9]*$!) { print F $cvtrm_tablerentries_11, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_11<br>";}
print F "Used Table Entry 11 - "; if (exists $auth_id_list{$cvtrm_selfid_11}) { my $cvtrm_selfid_11_result = $auth_id_list{$cvtrm_selfid_11}; print F "$cvtrm_selfid_11 - $cvtrm_selfid_11_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm_selfid_11<br>";}
print F "Self Data Validation - "; if ($cvtrm_11 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_11<br>";} else { print F $ok; push(@ok, "OK");}
}

if ($cvtrm_vtrm0_ftuentries >= 12) {
print F "<br>Table Entry 12 - "; if ($cvtrm_tableentry_12 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tableentry_12<br>";}
print F "Reserved Table Entry 12 - "; if (exists $auth_id_list{$cvtrm_tablerentries_12}){ my $cvtrm_rentries_12_result = $auth_id_list{$cvtrm_tablerentries_12}; print F "$cvtrm_tablerentries_12 - $cvtrm_rentries_12_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm_tablerentries_12 =~ m!^[0-9]*$!) { print F $cvtrm_tablerentries_12, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_12<br>";}
print F "Used Table Entry 12 - "; if (exists $auth_id_list{$cvtrm_selfid_12}) { my $cvtrm_selfid_12_result = $auth_id_list{$cvtrm_selfid_12}; print F "$cvtrm_selfid_12 - $cvtrm_selfid_12_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm_selfid_12<br>";}
print F "Self Data Validation - "; if ($cvtrm_12 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm_tablerentries_12<br>";} else { print F $ok; push(@ok, "OK");}
} 


print F "<br><b>VTRM 0 Continued:</b><br>"; 

my %cvtrm_vtrm0_finish = (
'1' => '15487208',
'2' => '15487304',
'3' => '15487400',
'4' => '15487496',
'5' => '15487592',
'6' => '15487688',
'7' => '15487784',
'8' => '15487880',
'9' => '15487976',
'10' => '15488072',
'11' => '15488168',
'12' => '15488264',
);

if (exists $cvtrm_vtrm0_finish{$cvtrm_vtrm0_ftuentries}){ my $cvtrm_vtrm0_finish_result = $cvtrm_vtrm0_finish{$cvtrm_vtrm0_ftuentries}; 
my $cvtrm_vtrm0_entriesfinish_size = 15587144 - $cvtrm_vtrm0_finish_result; #EDD748 
seek($bin, $cvtrm_vtrm0_finish_result, 0);read($bin, my $cvtrm_vtrm0_entriesfilled, $cvtrm_vtrm0_entriesfinish_size); $cvtrm_vtrm0_entriesfilled = uc ascii_to_hex($cvtrm_vtrm0_entriesfilled);
print F "Filled Area - "; if ($cvtrm_vtrm0_entriesfilled =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}
} 
print F "Encrypted Sequence - "; if ($cvtrm_vtrm0_sequence =~ m![$cvtrm_vtrm0_sequence_key]*!) { print F $cvtrm_vtrm0_sequence_key, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm_vtrm0_sequence_key<br>";}

######################################################################
print "\nChecking VTRM 1...\n\n"; 

#CVTRM 1
seek($bin, 0xEE0000, 0);read($bin, my $cvtrm1_header ,0x04); 
seek($bin, 0xEE0004, 0);read($bin, my $cvtrm1_filler ,0x0C); $cvtrm1_filler = uc ascii_to_hex($cvtrm1_filler);
seek($bin, 0xEE0010, 0);read($bin, my $cvtrm1_structure ,0x3FF0); $cvtrm1_structure = uc ascii_to_hex($cvtrm1_structure);

#VTRM 1
seek($bin, 0xEE4000, 0);read($bin, my $cvtrm1_vtrm1 ,0x10); $cvtrm1_vtrm1 = uc ascii_to_hex($cvtrm1_vtrm1);
seek($bin, 0xEE4010, 0);read($bin, my $cvtrm1_vtrm1_sha1 ,0x14); $cvtrm1_vtrm1_sha1 = uc ascii_to_hex($cvtrm1_vtrm1_sha1);
seek($bin, 0xEE4024, 0);read($bin, my $cvtrm1_vtrm1_unknown ,0x04); $cvtrm1_vtrm1_unknown = uc ascii_to_hex($cvtrm1_vtrm1_unknown);
seek($bin, 0xEE4028, 0);read($bin, my $cvtrm1_vtrm1_rentries ,0x08); $cvtrm1_vtrm1_rentries = uc ascii_to_hex($cvtrm1_vtrm1_rentries);
seek($bin, 0xEE4030, 0);read($bin, my $cvtrm1_vtrm1_ftrentries ,0x08); $cvtrm1_vtrm1_ftrentries = uc ascii_to_hex($cvtrm1_vtrm1_ftrentries);
seek($bin, 0xEE4038, 0);read($bin, my $cvtrm1_vtrm1_ftuentries ,0x08); $cvtrm1_vtrm1_ftuentries = uc ascii_to_hex($cvtrm1_vtrm1_ftuentries);
seek($bin, 0xEE4040, 0);read($bin, my $cvtrm1_vtrm1_ftentries ,0x1050); $cvtrm1_vtrm1_ftentries = uc ascii_to_hex($cvtrm1_vtrm1_ftentries);
$cvtrm1_vtrm1_rentries = hex($cvtrm1_vtrm1_rentries); $cvtrm1_vtrm1_ftuentries = hex($cvtrm1_vtrm1_ftuentries); $cvtrm1_vtrm1_ftrentries = hex($cvtrm1_vtrm1_ftrentries);

#vtrm1SELFDATA

### self block one
seek($bin, 0xEE5088, 0);read($bin, my $cvtrm1_tableentry_1 ,0x08);  $cvtrm1_tableentry_1 = uc ascii_to_hex($cvtrm1_tableentry_1); #920/self
seek($bin, 0xEE5090, 0);read($bin, my $cvtrm1_tablerentries_1 ,0x08);  $cvtrm1_tablerentries_1 = uc ascii_to_hex($cvtrm1_tablerentries_1); #self/unknown
seek($bin, 0xEE5098, 0);read($bin, my $cvtrm1_selfid_1 ,0x08);  $cvtrm1_selfid_1 = uc ascii_to_hex($cvtrm1_selfid_1); #self
seek($bin, 0xEE50A0, 0);read($bin, my $cvtrm1_1 ,0x48); $cvtrm1_1 = uc ascii_to_hex($cvtrm1_1); #selfdata

### self block two
seek($bin, 0xEE50E8, 0);read($bin, my $cvtrm1_tableentry_2 ,0x08);  $cvtrm1_tableentry_2 = uc ascii_to_hex($cvtrm1_tableentry_2); #920
seek($bin, 0xEE50F0, 0);read($bin, my $cvtrm1_tablerentries_2 ,0x08);  $cvtrm1_tablerentries_2 = uc ascii_to_hex($cvtrm1_tablerentries_2); #self/unknown
seek($bin, 0xEE50F8, 0);read($bin, my $cvtrm1_selfid_2 ,0x08);  $cvtrm1_selfid_2 = uc ascii_to_hex($cvtrm1_selfid_2); #self
seek($bin, 0xEE5100, 0);read($bin, my $cvtrm1_2 ,0x48); $cvtrm1_2 = uc ascii_to_hex($cvtrm1_2); #selfdata

### self block three
seek($bin, 0xEE5148, 0);read($bin, my $cvtrm1_tableentry_3 ,0x08);  $cvtrm1_tableentry_3 = uc ascii_to_hex($cvtrm1_tableentry_3); #920
seek($bin, 0xEE5150, 0);read($bin, my $cvtrm1_tablerentries_3 ,0x08);  $cvtrm1_tablerentries_3 = uc ascii_to_hex($cvtrm1_tablerentries_3); #self/unknown
seek($bin, 0xEE5158, 0);read($bin, my $cvtrm1_selfid_3 ,0x08);  $cvtrm1_selfid_3 = uc ascii_to_hex($cvtrm1_selfid_3); #self
seek($bin, 0xEE5160, 0);read($bin, my $cvtrm1_3 ,0x48); $cvtrm1_3 = uc ascii_to_hex($cvtrm1_3); #selfdata

### self block four
seek($bin, 0xEE51A8, 0);read($bin, my $cvtrm1_tableentry_4 ,0x08);  $cvtrm1_tableentry_4 = uc ascii_to_hex($cvtrm1_tableentry_4); #920
seek($bin, 0xEE51B0, 0);read($bin, my $cvtrm1_tablerentries_4 ,0x08);  $cvtrm1_tablerentries_4 = uc ascii_to_hex($cvtrm1_tablerentries_4); #self/unknown
seek($bin, 0xEE51B8, 0);read($bin, my $cvtrm1_selfid_4 ,0x08);  $cvtrm1_selfid_4 = uc ascii_to_hex($cvtrm1_selfid_4); #self
seek($bin, 0xEE51C0, 0);read($bin, my $cvtrm1_4 ,0x48); $cvtrm1_4 = uc ascii_to_hex($cvtrm1_4); #selfdata

### self block five
seek($bin, 0xEE5208, 0);read($bin, my $cvtrm1_tableentry_5 ,0x08);  $cvtrm1_tableentry_5 = uc ascii_to_hex($cvtrm1_tableentry_5); #920
seek($bin, 0xEE5210, 0);read($bin, my $cvtrm1_tablerentries_5 ,0x08);  $cvtrm1_tablerentries_5 = uc ascii_to_hex($cvtrm1_tablerentries_5); #self/unknown
seek($bin, 0xEE5218, 0);read($bin, my $cvtrm1_selfid_5 ,0x08);  $cvtrm1_selfid_5 = uc ascii_to_hex($cvtrm1_selfid_5); #self
seek($bin, 0xEE5220, 0);read($bin, my $cvtrm1_5 ,0x48); $cvtrm1_5 = uc ascii_to_hex($cvtrm1_5); #selfdata

### self block six
seek($bin, 0xEE5268, 0);read($bin, my $cvtrm1_tableentry_6 ,0x08);  $cvtrm1_tableentry_6 = uc ascii_to_hex($cvtrm1_tableentry_6); #920
seek($bin, 0xEE5270, 0);read($bin, my $cvtrm1_tablerentries_6 ,0x08);  $cvtrm1_tablerentries_6 = uc ascii_to_hex($cvtrm1_tablerentries_6); #self/unknown
seek($bin, 0xEE5278, 0);read($bin, my $cvtrm1_selfid_6 ,0x08);  $cvtrm1_selfid_6 = uc ascii_to_hex($cvtrm1_selfid_6); #self
seek($bin, 0xEE5280, 0);read($bin, my $cvtrm1_6 ,0x48); $cvtrm1_6 = uc ascii_to_hex($cvtrm1_6); #selfdata

### self block seven
seek($bin, 0xEE52C8, 0);read($bin, my $cvtrm1_tableentry_7 ,0x08);  $cvtrm1_tableentry_7 = uc ascii_to_hex($cvtrm1_tableentry_7); #920
seek($bin, 0xEE52D0, 0);read($bin, my $cvtrm1_tablerentries_7 ,0x08);  $cvtrm1_tablerentries_7 = uc ascii_to_hex($cvtrm1_tablerentries_7); #self/unknown
seek($bin, 0xEE52D8, 0);read($bin, my $cvtrm1_selfid_7 ,0x08);  $cvtrm1_selfid_7 = uc ascii_to_hex($cvtrm1_selfid_7); #self
seek($bin, 0xEE52E0, 0);read($bin, my $cvtrm1_7 ,0x48); $cvtrm1_7 = uc ascii_to_hex($cvtrm1_7); #selfdata

### self block eight
seek($bin, 0xEE5328, 0);read($bin, my $cvtrm1_tableentry_8 ,0x08);  $cvtrm1_tableentry_8 = uc ascii_to_hex($cvtrm1_tableentry_8); #920
seek($bin, 0xEE5330, 0);read($bin, my $cvtrm1_tablerentries_8 ,0x08);  $cvtrm1_tablerentries_8 = uc ascii_to_hex($cvtrm1_tablerentries_8); #self/unknown
seek($bin, 0xEE5338, 0);read($bin, my $cvtrm1_selfid_8 ,0x08);  $cvtrm1_selfid_8 = uc ascii_to_hex($cvtrm1_selfid_8); #self
seek($bin, 0xEE5340, 0);read($bin, my $cvtrm1_8 ,0x48); $cvtrm1_8 = uc ascii_to_hex($cvtrm1_8); #selfdata

### self block nine
seek($bin, 0xEE5388, 0);read($bin, my $cvtrm1_tableentry_9 ,0x08);  $cvtrm1_tableentry_9 = uc ascii_to_hex($cvtrm1_tableentry_9); #920
seek($bin, 0xEE5390, 0);read($bin, my $cvtrm1_tablerentries_9 ,0x08);  $cvtrm1_tablerentries_9 = uc ascii_to_hex($cvtrm1_tablerentries_9); #self/unknown
seek($bin, 0xEE5398, 0);read($bin, my $cvtrm1_selfid_9 ,0x08);  $cvtrm1_selfid_9 = uc ascii_to_hex($cvtrm1_selfid_9); #self
seek($bin, 0xEE53A0, 0);read($bin, my $cvtrm1_9 ,0x48); $cvtrm1_9 = uc ascii_to_hex($cvtrm1_9); #selfdata

### self block ten
seek($bin, 0xEE53E8, 0);read($bin, my $cvtrm1_tableentry_10 ,0x08);  $cvtrm1_tableentry_10 = uc ascii_to_hex($cvtrm1_tableentry_10); #920
seek($bin, 0xEE53F0, 0);read($bin, my $cvtrm1_tablerentries_10 ,0x08);  $cvtrm1_tablerentries_10 = uc ascii_to_hex($cvtrm1_tablerentries_10); #self/unknown
seek($bin, 0xEE53F8, 0);read($bin, my $cvtrm1_selfid_10 ,0x08);  $cvtrm1_selfid_10 = uc ascii_to_hex($cvtrm1_selfid_10); #self
seek($bin, 0xEE5400, 0);read($bin, my $cvtrm1_10 ,0x48); $cvtrm1_10 = uc ascii_to_hex($cvtrm1_10); #selfdata

### self block eleven
seek($bin, 0xEE5448, 0);read($bin, my $cvtrm1_tableentry_11 ,0x08);  $cvtrm1_tableentry_11 = uc ascii_to_hex($cvtrm1_tableentry_11); #920
seek($bin, 0xEE5450, 0);read($bin, my $cvtrm1_tablerentries_11 ,0x08);  $cvtrm1_tablerentries_11 = uc ascii_to_hex($cvtrm1_tablerentries_11); #self/unknown
seek($bin, 0xEE5458, 0);read($bin, my $cvtrm1_selfid_11 ,0x08);  $cvtrm1_selfid_11 = uc ascii_to_hex($cvtrm1_selfid_11); #self
seek($bin, 0xEE5460, 0);read($bin, my $cvtrm1_11 ,0x48); $cvtrm1_11 = uc ascii_to_hex($cvtrm1_11); #selfdata

### self block twelve
seek($bin, 0xEE54A8, 0);read($bin, my $cvtrm1_tableentry_12 ,0x08);  $cvtrm1_tableentry_12 = uc ascii_to_hex($cvtrm1_tableentry_12); #920
seek($bin, 0xEE54B0, 0);read($bin, my $cvtrm1_tablerentries_12 ,0x08);  $cvtrm1_tablerentries_12 = uc ascii_to_hex($cvtrm1_tablerentries_12); #self/unknown
seek($bin, 0xEE54B8, 0);read($bin, my $cvtrm1_selfid_12 ,0x08);  $cvtrm1_selfid_12 = uc ascii_to_hex($cvtrm1_selfid_12); #self
seek($bin, 0xEE54C0, 0);read($bin, my $cvtrm1_12 ,0x48); $cvtrm1_12 = uc ascii_to_hex($cvtrm1_12); #selfdata

#VTRM 0 Continued

seek($bin, 0xEFD748, 0);read($bin, my $cvtrm1_vtrm1_sequence_key,0x14); $cvtrm1_vtrm1_sequence_key = uc ascii_to_hex($cvtrm1_vtrm1_sequence_key);
seek($bin, 0xEFD748, 0);read($bin, my $cvtrm1_vtrm1_sequence,0x0F8C); $cvtrm1_vtrm1_sequence = uc ascii_to_hex($cvtrm1_vtrm1_sequence);

################################
print F "<br><b>CVTRM 1:</b><br>";

print F "Header - "; if ($cvtrm1_header eq "SCEI" or "VTRM" or "....") { print F "$cvtrm1_header", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_header<br>";}
print F "Filler -"; if ($cvtrm1_filler eq "FFFDFFFFFFFFFFFFFFFFFFFF" or "FFFFFFFFFFFFFFFFFFFFFFFF") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_filler<br>";}
print F "Filled Space -"; if ($cvtrm1_structure =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}

print F "<br><b>VTRM 1:</b><br>";

print F "Header - "; if ($cvtrm1_vtrm1 eq "000000005654524D0000000000000004" ) { print F "VTRM", $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_vtrm1<br>";}
print F "SHA1 Hash - "; if ($cvtrm1_vtrm1_sha1 =~ m![^FF]*$!) { print F "$cvtrm1_vtrm1_sha1", $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - $cvtrm1_vtrm1_sha1<br>";}
print F "Padding - "; if ($cvtrm1_vtrm1_unknown eq "000000E0" or "00000000") { print F "$cvtrm1_vtrm1_unknown", $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - $cvtrm1_vtrm1_unknown<br>";}
print F "X & Y Tables Reserved Entries - "; if ($cvtrm1_vtrm1_rentries =~ m!^[0-9]*$!) { print F $cvtrm1_vtrm1_rentries, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_vtrm1_rentries<br>";}
print F "Protected Files Table Reserved Entries - "; if ($cvtrm1_vtrm1_ftrentries =~ m!^[0-9]*$!) { print F $cvtrm1_vtrm1_ftrentries, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_vtrm1_ftrentries<br>";}
print F "Protected Files Table Used Entries - "; if ($cvtrm1_vtrm1_ftuentries =~ m!^[0-9]*$!) { print F $cvtrm1_vtrm1_ftuentries, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_vtrm1_ftuentries<br>";}
print F "Reserved Entries -"; if ($cvtrm1_vtrm1_ftentries =~ m!^[0000000000000][00A|00B|412][0-9A-Z]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - Too long to display!<br>";}


print F "<br><b>VTRM 1 Table Entries:</b><br>"; 

if ($cvtrm1_vtrm1_ftuentries >= 1) {
print F "Table Entry 1 - "; if ($cvtrm1_tableentry_1 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tableentry_1<br>";}
print F "Reserved Table Entry 1 - "; if (exists $auth_id_list{$cvtrm1_tablerentries_1}){ my $cvtrm1_rentries_1_result = $auth_id_list{$cvtrm1_tablerentries_1}; print F "$cvtrm1_tablerentries_1 - $cvtrm1_rentries_1_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm1_tablerentries_1 =~ m!^[0-9]*$!) { print F $cvtrm1_tablerentries_1, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_1<br>";}
print F "Used Table Entry 1 - "; if (exists $auth_id_list{$cvtrm1_selfid_1}) { my $cvtrm1_selfid_1_result = $auth_id_list{$cvtrm1_selfid_1}; print F "$cvtrm1_selfid_1 - $cvtrm1_selfid_1_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_selfid_1<br>";}
print F "Self Data Validation - "; if ($cvtrm1_1 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_1<br>";} else { print F $ok; push(@ok, "OK");}
}

if ($cvtrm1_vtrm1_ftuentries >= 2) {
print F "<br>Table Entry 2 - "; if ($cvtrm1_tableentry_2 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tableentry_2<br>";}
print F "Reserved Table Entry 2 - "; if (exists $auth_id_list{$cvtrm1_tablerentries_2}){ my $cvtrm1_rentries_2_result = $auth_id_list{$cvtrm1_tablerentries_2}; print F "$cvtrm1_tablerentries_2 - $cvtrm1_rentries_2_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm1_tablerentries_2 =~ m!^[0-9]*$!) { print F $cvtrm1_tablerentries_2, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_2<br>";}
print F "Used Table Entry 2 - "; if (exists $auth_id_list{$cvtrm1_selfid_2}) { my $cvtrm1_selfid_2_result = $auth_id_list{$cvtrm1_selfid_2}; print F "$cvtrm1_selfid_2 - $cvtrm1_selfid_2_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_selfid_2<br>";}
print F "Self Data Validation - "; if ($cvtrm1_2 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_2<br>";} else { print F $ok; push(@ok, "OK");}
} 

if ($cvtrm1_vtrm1_ftuentries >= 3) {
print F "<br>Table Entry 3 - "; if ($cvtrm1_tableentry_3 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tableentry_3<br>";}
print F "Reserved Table Entry 3 - "; if (exists $auth_id_list{$cvtrm1_tablerentries_3}){ my $cvtrm1_rentries_3_result = $auth_id_list{$cvtrm1_tablerentries_3}; print F "$cvtrm1_tablerentries_3 - $cvtrm1_rentries_3_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm1_tablerentries_3 =~ m!^[0-9]*$!) { print F $cvtrm1_tablerentries_3, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_3<br>";}
print F "Used Table Entry 3 - "; if (exists $auth_id_list{$cvtrm1_selfid_3}) { my $cvtrm1_selfid_3_result = $auth_id_list{$cvtrm1_selfid_3}; print F "$cvtrm1_selfid_3 - $cvtrm1_selfid_3_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_selfid_3<br>";}
print F "Self Data Validation - "; if ($cvtrm1_3 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_3<br>";} else { print F $ok; push(@ok, "OK");}
} 

if ($cvtrm1_vtrm1_ftuentries >= 4) {
print F "<br>Table Entry 4 - "; if ($cvtrm1_tableentry_4 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tableentry_4<br>";}
print F "Reserved Table Entry 4 - "; if (exists $auth_id_list{$cvtrm1_tablerentries_4}){ my $cvtrm1_rentries_4_result = $auth_id_list{$cvtrm1_tablerentries_4}; print F "$cvtrm1_tablerentries_4 - $cvtrm1_rentries_4_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm1_tablerentries_4 =~ m!^[0-9]*$!) { print F $cvtrm1_tablerentries_4, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_4<br>";}
print F "Used Table Entry 4 - "; if (exists $auth_id_list{$cvtrm1_selfid_4}) { my $cvtrm1_selfid_4_result = $auth_id_list{$cvtrm1_selfid_4}; print F "$cvtrm1_selfid_4 - $cvtrm1_selfid_4_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_selfid_4<br>";}
print F "Self Data Validation - "; if ($cvtrm1_4 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_4<br>";} else { print F $ok; push(@ok, "OK");}
} 

if ($cvtrm1_vtrm1_ftuentries >= 5) {
print F "<br>Table Entry 5 - "; if ($cvtrm1_tableentry_5 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tableentry_5<br>";}
print F "Reserved Table Entry 5 - "; if (exists $auth_id_list{$cvtrm1_tablerentries_5}){ my $cvtrm1_rentries_5_result = $auth_id_list{$cvtrm1_tablerentries_5}; print F "$cvtrm1_tablerentries_5 - $cvtrm1_rentries_5_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm1_tablerentries_5 =~ m!^[0-9]*$!) { print F $cvtrm1_tablerentries_5, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_5<br>";}
print F "Used Table Entry 5 - "; if (exists $auth_id_list{$cvtrm1_selfid_5}) { my $cvtrm1_selfid_5_result = $auth_id_list{$cvtrm1_selfid_5}; print F "$cvtrm1_selfid_5 - $cvtrm1_selfid_5_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_selfid_5<br>";}
print F "Self Data Validation - "; if ($cvtrm1_5 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_5<br>";} else { print F $ok; push(@ok, "OK");}
} 

if ($cvtrm1_vtrm1_ftuentries >= 6) {
print F "<br>Table Entry 6 - "; if ($cvtrm1_tableentry_6 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tableentry_6<br>";}
print F "Reserved Table Entry 6 - "; if (exists $auth_id_list{$cvtrm1_tablerentries_6}){ my $cvtrm1_rentries_6_result = $auth_id_list{$cvtrm1_tablerentries_6}; print F "$cvtrm1_tablerentries_6 - $cvtrm1_rentries_6_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm1_tablerentries_6 =~ m!^[0-9]*$!) { print F $cvtrm1_tablerentries_6, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_6<br>";}
print F "Used Table Entry 6 - "; if (exists $auth_id_list{$cvtrm1_selfid_6}) { my $cvtrm1_selfid_6_result = $auth_id_list{$cvtrm1_selfid_6}; print F "$cvtrm1_selfid_6 - $cvtrm1_selfid_6_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_selfid_6<br>";}
print F "Self Data Validation - "; if ($cvtrm1_6 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_6<br>";} else { print F $ok; push(@ok, "OK");}
} 

if ($cvtrm1_vtrm1_ftuentries >= 7) {
print F "<br>Table Entry 7 - "; if ($cvtrm1_tableentry_7 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tableentry_7<br>";}
print F "Reserved Table Entry 7 - "; if (exists $auth_id_list{$cvtrm1_tablerentries_7}){ my $cvtrm1_rentries_7_result = $auth_id_list{$cvtrm1_tablerentries_7}; print F "$cvtrm1_tablerentries_7 - $cvtrm1_rentries_7_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm1_tablerentries_7 =~ m!^[0-9]*$!) { print F $cvtrm1_tablerentries_7, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_7<br>";}
print F "Used Table Entry 7 - "; if (exists $auth_id_list{$cvtrm1_selfid_7}) { my $cvtrm1_selfid_7_result = $auth_id_list{$cvtrm1_selfid_7}; print F "$cvtrm1_selfid_7 - $cvtrm1_selfid_7_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_selfid_7<br>";}
print F "Self Data Validation - "; if ($cvtrm1_7 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_7<br>";} else { print F $ok; push(@ok, "OK");}
} 

if ($cvtrm1_vtrm1_ftuentries >= 8) {
print F "<br>Table Entry 8 - "; if ($cvtrm1_tableentry_8 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tableentry_8<br>";}
print F "Reserved Table Entry 8 - "; if (exists $auth_id_list{$cvtrm1_tablerentries_8}){ my $cvtrm1_rentries_8_result = $auth_id_list{$cvtrm1_tablerentries_8}; print F "$cvtrm1_tablerentries_8 - $cvtrm1_rentries_8_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm1_tablerentries_8 =~ m!^[0-9]*$!) { print F $cvtrm1_tablerentries_8, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_8<br>";}
print F "Used Table Entry 8 - "; if (exists $auth_id_list{$cvtrm1_selfid_8}) { my $cvtrm1_selfid_8_result = $auth_id_list{$cvtrm1_selfid_8}; print F "$cvtrm1_selfid_8 - $cvtrm1_selfid_8_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_selfid_8<br>";}
print F "Self Data Validation - "; if ($cvtrm1_8 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_8<br>";} else { print F $ok; push(@ok, "OK");}
}

if ($cvtrm1_vtrm1_ftuentries >= 9) {
print F "<br>Table Entry 9 - "; if ($cvtrm1_tableentry_9 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tableentry_9<br>";}
print F "Reserved Table Entry 9 - "; if (exists $auth_id_list{$cvtrm1_tablerentries_9}){ my $cvtrm1_rentries_9_result = $auth_id_list{$cvtrm1_tablerentries_9}; print F "$cvtrm1_tablerentries_9 - $cvtrm1_rentries_9_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm1_tablerentries_9 =~ m!^[0-9]*$!) { print F $cvtrm1_tablerentries_9, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_9<br>";}
print F "Used Table Entry 9 - "; if (exists $auth_id_list{$cvtrm1_selfid_9}) { my $cvtrm1_selfid_9_result = $auth_id_list{$cvtrm1_selfid_9}; print F "$cvtrm1_selfid_9 - $cvtrm1_selfid_9_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_selfid_9<br>";}
print F "Self Data Validation - "; if ($cvtrm1_9 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_9<br>";} else { print F $ok; push(@ok, "OK");}
} 

if ($cvtrm1_vtrm1_ftuentries >= 10) {
print F "<br>Table Entry 10 - "; if ($cvtrm1_tableentry_10 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tableentry_10<br>";}
print F "Reserved Table Entry 10 - "; if (exists $auth_id_list{$cvtrm1_tablerentries_10}){ my $cvtrm1_rentries_10_result = $auth_id_list{$cvtrm1_tablerentries_10}; print F "$cvtrm1_tablerentries_10 - $cvtrm1_rentries_10_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm1_tablerentries_10 =~ m!^[0-9]*$!) { print F $cvtrm1_tablerentries_10, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_10<br>";}
print F "Used Table Entry 10 - "; if (exists $auth_id_list{$cvtrm1_selfid_10}) { my $cvtrm1_selfid_10_result = $auth_id_list{$cvtrm1_selfid_10}; print F "$cvtrm1_selfid_10 - $cvtrm1_selfid_10_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_selfid_10<br>";}
print F "Self Data Validation - "; if ($cvtrm1_10 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_10<br>";} else { print F $ok; push(@ok, "OK");}
}

if ($cvtrm1_vtrm1_ftuentries >= 11) {
print F "<br>Table Entry 11 - "; if ($cvtrm1_tableentry_11 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tableentry_11<br>";}
print F "Reserved Table Entry 11 - "; if (exists $auth_id_list{$cvtrm1_tablerentries_11}){ my $cvtrm1_rentries_11_result = $auth_id_list{$cvtrm1_tablerentries_11}; print F "$cvtrm1_tablerentries_11 - $cvtrm1_rentries_11_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm1_tablerentries_11 =~ m!^[0-9]*$!) { print F $cvtrm1_tablerentries_11, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_11<br>";}
print F "Used Table Entry 11 - "; if (exists $auth_id_list{$cvtrm1_selfid_11}) { my $cvtrm1_selfid_11_result = $auth_id_list{$cvtrm1_selfid_11}; print F "$cvtrm1_selfid_11 - $cvtrm1_selfid_11_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_selfid_11<br>";}
print F "Self Data Validation - "; if ($cvtrm1_11 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_11<br>";} else { print F $ok; push(@ok, "OK");}
}

if ($cvtrm1_vtrm1_ftuentries >= 12) {
print F "<br>Table Entry 12 - "; if ($cvtrm1_tableentry_12 =~ m!^[0-9]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tableentry_12<br>";}
print F "Reserved Table Entry 12 - "; if (exists $auth_id_list{$cvtrm1_tablerentries_12}){ my $cvtrm1_rentries_12_result = $auth_id_list{$cvtrm1_tablerentries_12}; print F "$cvtrm1_tablerentries_12 - $cvtrm1_rentries_12_result", $ok; push(@ok, "OK")} 
elsif ($cvtrm1_tablerentries_12 =~ m!^[0-9]*$!) { print F $cvtrm1_tablerentries_12, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_12<br>";}
print F "Used Table Entry 12 - "; if (exists $auth_id_list{$cvtrm1_selfid_12}) { my $cvtrm1_selfid_12_result = $auth_id_list{$cvtrm1_selfid_12}; print F "$cvtrm1_selfid_12 - $cvtrm1_selfid_12_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_selfid_12<br>";}
print F "Self Data Validation - "; if ($cvtrm1_12 =~ m![^F]F{4,}[^F]!) { push(@danger, "Danger"); print F "$danger - $cvtrm1_tablerentries_12<br>";} else { print F $ok; push(@ok, "OK");}
} 


print F "<br><b>VTRM 1 Continued:</b><br>"; 

my %cvtrm1_vtrm1_finish = (
'1' => '15618280',
'2' => '15618376',
'3' => '15618472', #EE51A8
'4' => '15618568', #EE5208
'5' => '15618664', #EE5268
'6' => '15618760', #EE52C8
'7' => '15618856', #EE5328 (endof6)
'8' => '15618952',
'9' => '15619048',
'10' => '15619240',
'11' => '15619144',
'12' => '15619336',
);

if (exists $cvtrm1_vtrm1_finish{$cvtrm1_vtrm1_ftuentries}){ my $cvtrm1_vtrm1_finish_result = $cvtrm1_vtrm1_finish{$cvtrm1_vtrm1_ftuentries}; 
my $cvtrm1_vtrm1_entriesfinish_size = 15718216 - $cvtrm1_vtrm1_finish_result; #EFD748 
seek($bin, $cvtrm1_vtrm1_finish_result, 0);read($bin, my $cvtrm1_vtrm1_entriesfilled, $cvtrm1_vtrm1_entriesfinish_size); $cvtrm1_vtrm1_entriesfilled = uc ascii_to_hex($cvtrm1_vtrm1_entriesfilled);
print F "Filled Area - "; if ($cvtrm1_vtrm1_entriesfilled =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}
} 
print F "Encrypted Sequence - "; if ($cvtrm1_vtrm1_sequence =~ m![$cvtrm1_vtrm1_sequence_key]*!) { print F $cvtrm1_vtrm1_sequence_key, $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cvtrm1_vtrm1_sequence_key<br>";}


####################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################
print "\nChecking Second Region Header...\n\n"; 

seek($bin, 0xF00000, 0); read($bin, my $secondregion_blank, 0x10); $secondregion_blank = uc ascii_to_hex($secondregion_blank);
seek($bin, 0xF00014, 0); read($bin, my $faceoff2, 0x04); $faceoff2 = uc ascii_to_hex($faceoff2);
seek($bin, 0xF0001C, 0); read($bin, my $deadbeef2, 0x04); $deadbeef2 = uc ascii_to_hex($deadbeef2);
seek($bin, 0xF00027, 0); read($bin, my $secondregion_count, 0x01); $secondregion_count = uc ascii_to_hex($secondregion_count);
seek($bin, 0xF0002F, 0); read($bin, my $secondregion_unknown, 0x01); $secondregion_unknown = uc ascii_to_hex($secondregion_unknown);
seek($bin, 0xF00030, 0); read($bin, my $secondregion_filledblock, 0x90); $secondregion_filledblock = uc ascii_to_hex($secondregion_filledblock);

seek($bin, 0xF000D0, 0); read($bin, my $secondregion_authid1, 0x08); $secondregion_authid1 = uc ascii_to_hex($secondregion_authid1);
seek($bin, 0xF000E0, 0); read($bin, my $secondregion_authid2, 0x08); $secondregion_authid2 = uc ascii_to_hex($secondregion_authid2);
seek($bin, 0xF00160, 0); read($bin, my $secondregion_authid3, 0x08); $secondregion_authid3 = uc ascii_to_hex($secondregion_authid3);
seek($bin, 0xF00170, 0); read($bin, my $secondregion_authid4, 0x08); $secondregion_authid4 = uc ascii_to_hex($secondregion_authid4);


print F "<div id=\"srgeneric\"></div>";
print F "<div style = \"text-align:right; float:right\"><a href=\"#Top\">Return</a></div><br>";
print F "<br><b>Second Region Header:</b><br>";

print F "Unknown Blank -"; if ($secondregion_blank eq "00000000000000000000000000000000") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $secondregion_blank<br>";}
print F "Magic Header 2 - "; if ($faceoff2 eq "0FACE0FF" and $deadbeef2 eq "DEADFACE") { print F "$faceoff2 - $deadbeef2", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $faceoff2 $deadbeef2<br>";}
print F "Region Count - "; if ($secondregion_count eq "03") { print F "$secondregion_count", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $secondregion_count<br>";}
print F "Unknown - "; if ($secondregion_unknown eq "02" or "01") { print F "$secondregion_unknown", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $secondregion_unknown<br>";}
print F "Blank Filled Block -"; if ($secondregion_filledblock =~ m!^[00]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}

# print F "<br><b>Second Region Auth IDs:</b><br>"; 
# if (exists $auth_id_list{$secondregion_authid1}){ my $secondregion_authid1_result = $auth_id_list{$secondregion_authid1}; print F "$secondregion_authid1 - $secondregion_authid1_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $secondregion_authid1<br>";}
# if (exists $auth_id_list{$secondregion_authid2}){ my $secondregion_authid2_result = $auth_id_list{$secondregion_authid2}; print F "$secondregion_authid2 - $secondregion_authid2_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $secondregion_authid2<br>";}
# if (exists $auth_id_list{$secondregion_authid3}){ my $secondregion_authid3_result = $auth_id_list{$secondregion_authid3}; print F "$secondregion_authid3 - $secondregion_authid3_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $secondregion_authid3<br>";}
# if (exists $auth_id_list{$secondregion_authid4}){ my $secondregion_authid4_result = $auth_id_list{$secondregion_authid4}; print F "$secondregion_authid4 - $secondregion_authid4_result", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $secondregion_authid4<br>";}


####################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################
print "\nChecking Second Region Block 0...\n\n"; 

seek($bin, 0xF000C0, 0); read($bin, my $ub_sectorstart, 0x08);
seek($bin, 0xF000C8, 0); read($bin, my $ub_count, 0x08);
seek($bin, 0xF000D0, 0); read($bin, my $ub_authid, 0x08);
seek($bin, 0xF000D8, 0); read($bin, my $ub_unknown, 0x08);
seek($bin, 0xF000E0, 0); read($bin, my $ub_authid2, 0x08);
seek($bin, 0xF000E8, 0); read($bin, my $ub_unknown2, 0x08);
seek($bin, 0xF000F0, 0); read($bin, my $ub_filled, 0x60);

print F "<br><b>Second Region Unknown Block 0:</b><br>";

my $ub_sectorstart_convert = uc ascii_to_hex($ub_sectorstart);
my $ub_count_convert = uc ascii_to_hex($ub_count);
my $ub_authid_convert = uc ascii_to_hex($ub_authid);
my $ub_unknown_convert = uc ascii_to_hex($ub_unknown);
my $ub_authid2_convert = uc ascii_to_hex($ub_authid2);
my $ub_unknown2_convert = uc ascii_to_hex($ub_unknown2);
my $ub_filled_convert = uc ascii_to_hex($ub_filled);

print F "Sector Start -"; if ($ub_sectorstart_convert eq "0000000000007900") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $ub_sectorstart_convert<br>";}
print F "Count - "; if ($ub_count_convert eq "0000000000000100") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $ub_count_convert<br>";}
print F "Auth ID - "; if ($ub_authid_convert eq "1070000001000001") { print F "$ub_authid_convert (SCE_CELLOS_PME)", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ub_authid_convert<br>";}
print F "Unknown - "; if ($ub_unknown_convert eq "0000000000000003") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $ub_unknown_convert<br>";}
print F "Auth ID -"; if ($ub_authid2_convert eq "1070000002000001") { print F "$ub_authid2_convert (PS3_LPAR)", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ub_authid2_convert<br>";}
print F "Unknown - "; if ($ub_unknown2_convert eq "0000000000000003") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $ub_unknown2_convert<br>";}
print F "Blank Filled Block -"; if ($ub_filled_convert =~ m!^[00]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}

####################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################
print "\nChecking Second Region Block 1...\n\n"; 

seek($bin, 0xF00150, 0); read($bin, my $ub2_sectorstart, 0x08);
seek($bin, 0xF00158, 0); read($bin, my $ub2_count, 0x08);
seek($bin, 0xF00160, 0); read($bin, my $ub2_authid, 0x08);
seek($bin, 0xF00168, 0); read($bin, my $ub2_unknown, 0x08);
seek($bin, 0xF00170, 0); read($bin, my $ub2_authid2, 0x08);
seek($bin, 0xF00178, 0); read($bin, my $ub2_unknown2, 0x08);
seek($bin, 0xF00180, 0); read($bin, my $ub2_filled, 0x680);
seek($bin, 0xF00800, 0); read($bin, my $ub2_filled25, 0x800);
seek($bin, 0xF01000, 0); read($bin, my $ub2_filled2, 0x1F000);

print F "<br><b>Second Region Unknown Block 1:</b><br>";

my $ub2_sectorstart_convert = uc ascii_to_hex($ub2_sectorstart);
my $ub2_count_convert = uc ascii_to_hex($ub2_count);
my $ub2_authid_convert = uc ascii_to_hex($ub2_authid);
my $ub2_unknown_convert = uc ascii_to_hex($ub2_unknown);
my $ub2_authid2_convert = uc ascii_to_hex($ub2_authid2);
my $ub2_unknown2_convert = uc ascii_to_hex($ub2_unknown2);
my $ub2_filled_convert = uc ascii_to_hex($ub2_filled);
my $ub2_filled25_convert = uc ascii_to_hex($ub2_filled25);
my $ub2_filled2_convert = uc ascii_to_hex($ub2_filled2);

print F "Sector Start -"; if ($ub2_sectorstart_convert eq "0000000000007A00") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $ub2_sectorstart_convert<br>";}
print F "Count - "; if ($ub2_count_convert eq "0000000000000400" or "0000000000000100") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $ub2_count_convert<br>";}
print F "Auth ID - "; if ($ub2_authid_convert eq "1070000001000001") { print F "$ub2_authid_convert (SCE_CELLOS_PME)", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ub2_authid_convert<br>";}
print F "Unknown - "; if ($ub2_unknown_convert eq "0000000000000003") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $ub2_unknown_convert<br>";}
print F "Auth ID -"; if ($ub2_authid2_convert eq "1070000002000001") { print F "$ub2_authid2_convert (PS3_LPAR)", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $ub2_authid2_convert<br>";}
print F "Unknown - "; if ($ub2_unknown2_convert eq "0000000000000003") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $ub2_unknown2_convert<br>";}
print F "Blank Filled Block - "; if ($ub2_filled_convert =~ m!^[00]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}
print F "Blank Filled Block 2 - "; if ($ub2_filled25_convert =~ m!^[00]*$!) { print F $ok; push(@ok, "OK");} elsif ($ub2_filled_convert =~ m!^[00]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}
print F "Filled Block - "; if ($ub2_filled2_convert =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}

####################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################
print "\nChecking CELL_EXTNOR_AREA...\n\n"; 

seek($bin, 0xF20000, 0); read($bin, my $cea_header, 0x10); #nc
seek($bin, 0xF20010, 0); read($bin, my $cea_sha1header, 0x010);
seek($bin, 0xF20040, 0); read($bin, my $cea_filled, 0x1C3);
seek($bin, 0xF20204, 0); read($bin, my $cea_hdmodel, 0x033); #nc
seek($bin, 0xF20237, 0); read($bin, my $cea_hdserial, 0x08); #nc
seek($bin, 0xF20240, 0); read($bin, my $cea_filled2, 0x1FDC0);

seek($bin, 0xF40000, 0); read($bin, my $cea_hash1, 0x40);
seek($bin, 0xF40030, 0); read($bin, my $cea_filled3, 0x1FFD0);

seek($bin, 0xF60000, 0); read($bin, my $cea_hash2, 0x40);
seek($bin, 0xF60060, 0); read($bin, my $cea_filled4, 0x93A0);
seek($bin, 0xF69400, 0); read($bin, my $ocrl0200, 0x130);
seek($bin, 0xF69530, 0); read($bin, my $cea_filled4_2, 0x6D0);
seek($bin, 0xF69C00, 0); read($bin, my $cea_filled5, 0x9BC0);

seek($bin, 0xF80000, 0); read($bin, my $cea2_hash1, 0x40); #same as f40000
seek($bin, 0xF80030, 0); read($bin, my $cea2_filled3, 0x1FFD0);

seek($bin, 0xFA0000, 0); read($bin, my $cea2_hash2, 0x40); #same as f60000m
seek($bin, 0xFA0060, 0); read($bin, my $cea2_filled4, 0x93A0);
seek($bin, 0xFA9400, 0); read($bin, my $ocrl02002, 0x130);
seek($bin, 0xFA9530, 0); read($bin, my $cea2_filled4_2, 0x6D0);
seek($bin, 0xFA9C00, 0); read($bin, my $cea2_filled5, 0x9BC0);

print F "<br><b>CELL_EXTNOR_AREA:</b><br>";

my $cea_sha1header_convert = uc ascii_to_hex($cea_sha1header);
my $cea_filled_convert = uc ascii_to_hex($cea_filled);
my $cea_filled2_convert = uc ascii_to_hex($cea_filled2);
my $cea_hdmodel_convert = unpack('H*', "$cea_hdmodel"); $cea_hdmodel_convert =~ s{00|20}{}g;  
my $cea_hdserial_convert = unpack('H*', "$cea_hdserial"); $cea_hdserial_convert =~ s{00|20}{}g;  
my $cea_hdmodel_convert2 = pack('H*', "$cea_hdmodel_convert"); my $cea_hdserial_convert2 = pack('H*', "$cea_hdserial_convert");

my $cea_hash1_convert = uc ascii_to_hex($cea_hash1);
my $cea_filled3_convert = uc ascii_to_hex($cea_filled3);
my $cea_hash2_convert = uc ascii_to_hex($cea_hash2);
my $cea_filled4_convert = uc ascii_to_hex($cea_filled4);
my $ocrl0200_convert = uc ascii_to_hex($ocrl0200);
my $cea_filled4_2_convert = uc ascii_to_hex($cea_filled4_2);
my $cea_filled5_convert = uc ascii_to_hex($cea_filled5);

my $cea2_hash1_convert = uc ascii_to_hex($cea2_hash1);
my $cea2_filled3_convert = uc ascii_to_hex($cea2_filled3);
my $cea2_hash2_convert = uc ascii_to_hex($cea2_hash2);
my $cea2_filled4_convert = uc ascii_to_hex($cea2_filled4);
my $ocrl02002_convert = uc ascii_to_hex($ocrl02002);
my $cea2_filled4_2_convert = uc ascii_to_hex($cea2_filled4_2);
my $cea2_filled5_convert = uc ascii_to_hex($cea2_filled5);

print F "Header - "; if ($cea_header eq "CELL_EXTNOR_AREA") { print F "$cea_header", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cea_header<br>";}
print F "SHA1 Header -"; if ($cea_sha1header_convert eq "00000001000000000000000000000000") { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cea_sha1header_convert<br>";}
print F "Unused Area -"; if ($cea_filled_convert =~ m!^[00]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}
print F "HD Model - "; if ($cea_hdmodel_convert =~ m![^FF]*$!) { print F $cea_hdmodel_convert2, $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cea_hdmodel_convert2<br>";}
print F "HD Serial - "; if ($cea_hdserial_convert =~ m![^FF]*$!) { print F $cea_hdserial_convert2, $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $cea_hdserial_convert2<br>";}
print F "Unused Area -"; if ($cea_filled2_convert =~ m!^[1|00]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}

print F "<br>Hash 1 -"; if ($cea_hash1_convert =~ m![^FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cea_hash1_convert<br>";}
print F "Unused Area -"; if ($cea_filled3_convert =~ m!^[FF|00]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}
print F "Hash 2 -"; if ($cea_hash2_convert =~ m![^FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cea_hash2_convert<br>";}
print F "Unused Area -"; if ($cea_filled4_convert =~ m!^[FF|00]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}
print F "OCRL0200 - "; if ($ocrl0200_convert eq "4F43524C3032303000000000000000000000000000000000000000000000000000000000000000000000000000000000A6503772078268FEEA9AA18C54192BE42FD885BA5F2FAAEDAC6B54FE310B8058A974D4EDF9777BB2305047F3C012AC266A40AD1914C2AD2C9236027850D408D406762C970D2A7A19F485016FCDC807C3252DF4CD462BFEF7B80A409F9722065E4BF102920111C1E0DDAC840D58C221662569A41AC8E9DB4C5D314EAF072A43903EDC4A80FDA706BB1F9BD4756C6C45CE1AA65DD19BE980C272CAA80B14C6B286E33786E6ADDE2CF9763D1862DD77AD7132F111FD179E6850B3A57F413719633A7808194DCA47ADFF3589523E1839F5A54B98D6C06668E0CA4B9F1A421EA2EE79E6586FFF58B1FE4FDBFD276F4CEC6C9FB4B7F89D304A1E83154708B6FB5100DA") { print F $ok; push(@ok, "OK");} elsif ($ocrl0200_convert=~ m!^[FF|00]*$!) { print F "Not Found", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - Too long to display!<br>";}
print F "Unused Area -"; if ($cea_filled4_2_convert =~ m!^[FF|00]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}
print F "Filled Area -"; if ($cea_filled5_convert =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}

print F "<br>Hash 1 -"; if ($cea2_hash1_convert eq $cea_hash1_convert) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cea2_hash1_convert<br>";}
print F "Unused Area -"; if ($cea2_filled3_convert =~ m!^[FF|00]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}
print F "Hash 2 -"; if ($cea2_hash2_convert eq $cea2_hash2_convert) { print F $ok; push(@ok, "OK");} else { push(@danger, "Danger"); print F "$danger - $cea2_hash2_convert<br>";}
print F "Unused Area -"; if ($cea2_filled4_convert =~ m!^[FF|00]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}
print F "OCRL0200 - "; if ($ocrl02002_convert eq "4F43524C3032303000000000000000000000000000000000000000000000000000000000000000000000000000000000A6503772078268FEEA9AA18C54192BE42FD885BA5F2FAAEDAC6B54FE310B8058A974D4EDF9777BB2305047F3C012AC266A40AD1914C2AD2C9236027850D408D406762C970D2A7A19F485016FCDC807C3252DF4CD462BFEF7B80A409F9722065E4BF102920111C1E0DDAC840D58C221662569A41AC8E9DB4C5D314EAF072A43903EDC4A80FDA706BB1F9BD4756C6C45CE1AA65DD19BE980C272CAA80B14C6B286E33786E6ADDE2CF9763D1862DD77AD7132F111FD179E6850B3A57F413719633A7808194DCA47ADFF3589523E1839F5A54B98D6C06668E0CA4B9F1A421EA2EE79E6586FFF58B1FE4FDBFD276F4CEC6C9FB4B7F89D304A1E83154708B6FB5100DA") { print F $ok; push(@ok, "OK");} elsif ($ocrl02002_convert=~ m!^[FF|00]*$!) { print F "Not Found", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - Too long to display!<br>";}
print F "Unused Area -"; if ($cea2_filled4_2_convert =~ m!^[FF|00]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}
print F "Filled Area -"; if ($cea2_filled5_convert =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}


############################################################################################################################################
print "\nChecking Lv0ldr/Bootldr...\n\n"; 

seek($bin, 0xFC0004, 0); read($bin, my $bootldr_revision_key, 0x0C); $bootldr_revision_key = uc ascii_to_hex($bootldr_revision_key);
seek($bin, 0xFC0002, 0); read($bin, my $bootldr, 0x02); $bootldr = uc ascii_to_hex($bootldr);
seek($bin, 0xFC0012, 0); read($bin, my $bootldr2, 0x02);$bootldr2 = uc ascii_to_hex($bootldr2);
seek($bin, 0xFC0014, 0); read($bin, my $bootldr_pcn ,0x0C); $bootldr_pcn = uc ascii_to_hex($bootldr_pcn); 

print F "<div id=\"lv0perconsole\"></div>";
print F "<div style = \"text-align:right; float:right\"><a href=\"#Top\">Return</a></div><br>";
print F "<br><b>Lv0ldr/Bootldr:</b><br>"; 

my $bootldr_dec = hex($bootldr);
my $bootldr_calc = ($bootldr_dec * 16 + 64);
my $bootldr_calc_convert = uc sprintf("%x", $bootldr_calc);
my $bootldr_size_list = '';
my %bootldr_size_list = map { $_ => 1 } ("2F200","2EF80","2EE70","2EAF0","2EB70","2F170","2F3F0","2F4F0","2F570","2F5F0","2FFF0","300F0","30070","301F0");
my %bootldr_list = map { $_ => 1 } ("2EF4","2EE3","2EAB","2EB3","2F13","2F1C","2F3B","2F4B","2F53","2F5B","2FFB","300B","3003","301B");

my $bootldr_filled_calc = hex("FC0000"); $bootldr_filled_calc = ($bootldr_calc + $bootldr_filled_calc); 
seek($bin, $bootldr_filled_calc, 0); read($bin, my $bootldr_filled ,0xFFFFF0); $bootldr_filled = uc ascii_to_hex($bootldr_filled); 

print F "Encrypted Binary Size - "; if (exists $bootldr_list{$bootldr}) { print F "$bootldr", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $bootldr<br>";}
print F "Decrypted Binary Size - "; if (exists $bootldr_list{$bootldr2}) { print F "$bootldr2", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $bootldr2<br>";}
print F "Calculated Bootldr Size - "; if (exists $bootldr_size_list{$bootldr_calc_convert}) { print F "$bootldr_calc_convert", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $bootldr_calc_convert<br>";}
print F "Rev Key - "; if (exists $bootldr_revision_key_list{$bootldr_revision_key}) { my $bootldr_revision_key_result = $bootldr_revision_key_list{$bootldr_revision_key}; print F "$bootldr_revision_key ($bootldr_revision_key_result)", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $bootldr_revision_key<br>";}
print F "PerConsole Nonce - "; if ($bootldr_pcn =~ m![^00|FF]*$!) { print F "$bootldr_pcn", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $bootldr_pcn<br>";}
print F "Filled Area"; if ($bootldr_filled =~ m!^[FF]*$!) { print F $ok; push(@ok, "OK");} elsif ($bootldr eq "301B") { print F $ok; push(@ok, "OK");} else { push(@warning, "WARNING"); print F "$warning - Too long to display!<br>";}

print "\nChecking Lv0ldr/Bootldr for Corruption...\n\n"; 

$ra->add( '([^ÿ]ÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿ[^ÿ])' );
$ra->add( '([^ÿ]ÿÿÿÿÿÿÿÿ[^ÿ])' );
$ra->add( '([^ÿ]ÿ{3,}[^ÿ])' );
$ra->add( '([^\0]\0{8}[^\0])' );
$ra->add( '([^\0]\0{16}[^\0])' );
$ra->add( '([^\0|@|r|!|?]\0{3,}[^\0|?])' );
$regex = $ra->re; my @matches_bootldr; my @matches_bootldr2;
seek($bin, 0xFC0000, 0);read($bin, my $match_bootldr, 0xFFFFF0);
#$match = uc ascii_to_hex($match); 
while ($match_bootldr =~ m/($regex)/g){
    my $match_bootldr = $1;
    my $offset = $-[0] + 0xFC0000;
	$offset = uc sprintf("%x",$offset);
    push @matches_bootldr, "[$match_bootldr] found at offset: 0x$offset ";
	push @matches_bootldr2, "Corruption found at offset: 0x$offset";
}
print F "<br><b>Lv0ldr/Bootldr Corrupt Sequence Check:</b><br>"; 
my $bootldr_matches = grep {defined $_} @matches_bootldr2;
# if ($bootldr_matches = 1) {print F "$_ - $warning<br>" foreach @matches_bootldr2; push(@warning, "WARNING")} 
# elsif ($bootldr_matches = 2) {print F "$_ - $warning<br>" foreach @matches_bootldr2; push(@warning, "WARNING")} 
# elsif ($bootldr_matches < 3) {print F "$_ - $danger<br>" foreach @matches_bootldr2; push(@danger, "DANGER")} 
# elsif ($bootldr_matches eq 1) {print F "Nothing Found! $ok"; push(@ok, "OK")}
# print $bootldr_matches;

if (grep {defined($_)} @matches_bootldr2) {print F "$_ - $warning<br>" foreach @matches_bootldr2; push(@warning, "WARNING")} else {print F "Nothing Found! $ok"; push(@ok, "OK");}

############################################################################################################################################ 
print "\nCalculating Lv0ldr/Bootldr Statistics...\n\n"; 

print F "<br><b>Lv0ldr/Bootldr Encrypted Statistics:</b><br>"; 

my %bootldr_stats;

seek($bin, 0xFC0000, 0); read($bin, my $bootldr_stats_range, $bootldr_calc);while () {$bootldr_stats{sprintf "%02X", ord $_}++ for split//, $bootldr_stats_range; last;}

my @list2 = values %bootldr_stats;
use Statistics::Lite qw(:all);
my $sum2 = sum @list2;
my $mean2 = mean @list2;
my $stddev2 = stddev @list2;
my %list2 = statshash @list2;
#print F statsinfo(@list2);

print F "Sum: "; if ($sum2 < 191215) { print F "$sum2 - $danger<br>"; push(@danger, "DANGER");} elsif ($sum2 > 197110) { print F "$sum2 - $danger<br>"; push(@danger, "DANGER");} else { print F $sum2, $ok; push(@ok, "OK")}
print F "Mean: "; if ($mean2 < 746.90) { print F "$mean2 - $danger<br>"; push(@danger, "DANGER");} elsif ($mean2 > 769.98) { print F "$mean2 - $danger<br>"; push(@danger, "DANGER");} else { print F $mean2, $ok; push(@ok, "OK")}
print F "Std Dev: "; 

if ($stddev2 < 24.830) { print F "$stddev2 - $warning<br>"; push(@warning, "WARNING")} 
elsif ($stddev2 > 30.750) { print F "$stddev2 - $danger<br>"; push(@danger, "DANGER")} 
else { print F $stddev2, $ok; push(@ok, "OK")}

#####################################

my %Count;    
my $total = 0; 
                     
    foreach my $char (split(//, $bootldr_stats_range)) { 
        $Count{$char}++;               
        $total++;                    
    }

my $bootldr_entropy = 0;                        
foreach my $char (keys %Count) {    
    my $p = $Count{$char}/$total;  
    $bootldr_entropy += $p * log($p);             
}
$bootldr_entropy = -$bootldr_entropy/log(2);                    

print F "Entropy: "; if ($bootldr_entropy < 7.99) { print F "$bootldr_entropy - $danger<br>"; push(@danger, "DANGER")} else { print F "$bootldr_entropy Bits", $ok; push(@ok, "OK")}
       


#old highest range was 29.940

# open(my $bootldrfile, '+>', "Bootldr") or die $!; binmode($bootldrfile);
# print $bootldrfile $bootldr_stats_range;
# close ($bootldrfile);
####################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################
print "\nCalculating Minimum Version...\n\n"; 

print F "<div id=\"other\"></div>";
print F "<div style = \"text-align:right; float:right\"><a href=\"#Top\">Return</a></div><br>";

if ($idps_convert eq "06" and $bootldr eq "2F1C") { print F "<br><b>Min Version:</b><br>2.30", $ok; push(@ok, "OK")} 
elsif ($idps_convert eq "06" and $bootldr eq "2EF4") { print F "<br><b>Min Version:</b><br>1.97", $ok; push(@ok, "OK")}
elsif ($idps_convert eq "06" and $bootldr eq "2EE3") { print F "<br><b>Min Version:</b><br>1.97", $ok; push(@ok, "OK")} 
elsif ($idps_convert eq "07" and $bootldr eq "2EE3") { print F "<br><b>Min Version:</b><br>2.30", $ok; push(@ok, "OK")} 
elsif ($idps_convert eq "07" and $bootldr eq "2EAB") { print F "<br><b>Min Version:</b><br>2.45", $ok; push(@ok, "OK")} 
elsif ($idps_convert eq "07" and $bootldr eq "2EF4") { print F "<br><b>Min Version:</b><br>2.30", $ok; push(@ok, "OK")} 
elsif ($idps_convert eq "08" and $bootldr eq "2EAB") { print F "<br><b>Min Version:</b><br>2.45", $ok; push(@ok, "OK")} 
elsif ($idps_convert eq "08" and $bootldr eq "2EB3") { print F "<br><b>Min Version:</b><br>2.45", $ok; push(@ok, "OK")} 
elsif ($idps_convert eq "08" and $bootldr eq "2F13") { print F "<br><b>Min Version:</b><br>2.30", $ok; push(@ok, "OK")}
elsif ($idps_convert eq "09" and $bootldr eq "2F13") { print F "<br><b>Min Version:</b><br>2.70", $ok; push(@ok, "OK")} 
elsif ($idps_convert eq "09" and $bootldr eq "2F3B") { print F "<br><b>Min Version:</b><br>2.70", $ok; push(@ok, "OK")} 
elsif ($idps_convert eq "0A" and $bootldr eq "2F4B") { print F "<br><b>Min Version:</b><br>3.20", $ok; push(@ok, "OK")}
elsif ($idps_convert eq "0B" and $bootldr eq "2F4B") { print F "<br><b>Min Version:</b><br>3.40", $ok; push(@ok, "OK")}
elsif ($idps_convert eq "0B" and $bootldr eq "2F53") { print F "<br><b>Min Version:</b><br>3.50", $ok; push(@ok, "OK")} 
elsif ($idps_convert eq "0B" and $bootldr eq "2F5B") { print F "<br><b>Min Version:</b><br>3.56", "<b><font color=orange> [DOWNGRADEABLE (With 3.56+ Patches)]</font></b><br>"; push(@warning, "WARNING") } 
elsif ($idps_convert eq "0B" and $bootldr eq "2FFB") { print F "<br><b>Min Version:</b><br>3.60", "<b><font color=orange> [NOT DOWNGRADEABLE]</font></b><br>"; push(@warning, "WARNING")} 
elsif ($idps_convert eq "0C" and $bootldr eq "2FFB") { print F "<br><b>Min Version:</b><br>3.60", "<b><font color=orange> [NOT DOWNGRADEABLE]</font></b><br>"; push(@warning, "WARNING")} 
elsif ($idps_convert eq "0C" and $bootldr eq "300B") { print F "<br><b>Min Version:</b><br>3.72", "<b><font color=orange> [NOT DOWNGRADEABLE]</font></b><br>"; push(@warning, "WARNING")} 
elsif ($idps_convert eq "0C" and $bootldr eq "3003") { print F "<br><b>Min Version:</b><br>3.72", "<b><font color=orange> [NOT DOWNGRADEABLE]</font></b><br>"; push(@warning, "WARNING")} 
elsif ($idps_convert eq "0D" and $bootldr eq "301B") { print F "<br><b>Min Version:</b><br>4.10", "<b><font color=orange> [NOT DOWNGRADEABLE]</font></b><br>"; push(@warning, "WARNING")} 
elsif ($idps_convert eq "06" and $bootldr eq "2F4B") { print F "<br><b>Min Version:</b><br>3.40", $ok; push(@ok, "OK")} 
else { print F "<br><b>Min Version:</b> $danger<br>"; push(@danger, "DANGER");}

############################################################################################################################################
print "\nFinding File Digest Keys...\n\n"; 

$ra->add( '627CB1808AB938E32C8C091708726A579E2586E4' );
$regex = $ra->re; my @matches_key;
seek($bin, 0x0, 0);read($bin, my $match_key, 0xFFFFF0);
$match_key = uc ascii_to_hex($match_key); 
while ($match_key =~ m/($regex)/g){
    my $match_key = $1;
    my $offset = $-[0];
	$offset = uc sprintf("%x",$offset);
    push @matches_key, "[$match_key] found at offset: 0x$offset ";
}
print F "<br><b>File Digest Key:</b><br>"; 
if (grep {defined($_)} @matches_key) {
my $key_count = grep {defined $_} @matches_key;
print F "Total number of keys: "; if ($key_count > 33) {print F $key_count, $ok; push(@ok, "OK")} else {print F "Mismatch! $key_count $warning<br>"};
print F "Key: 627CB1808AB938E32C8C091708726A579E2586E4", $ok; push(@ok, "OK");
}  else {print F "Nothing Found! $danger"; push(@danger, "DANGER");}

print "\nAuthenticiation IDs...\n\n"; 

$ra->add( '(107|102|105|1FF)0000\w\w\w00000\d' );

$regex = $ra->re; my @matches_authid;
seek($bin, 0x0, 0);read($bin, my $match_authid, 0xFFFFF0);
$match_authid = uc ascii_to_hex($match_authid); 
while ($match_authid =~ m/($regex)/g){
    my $match_authid = $1;
    my $offset_authid = $-[0]; $offset_authid = $offset_authid / 2;
	$offset_authid = uc sprintf("%x",$offset_authid);
    push @matches_authid, "$auth_id_list_nn{$match_authid} @ 0x$offset_authid ";
}
print F "<br><b>Bulk AuthID Check:</b><br>"; 
my $authid_count = grep {defined $_} @matches_authid;
print F "Total number of .self IDs: "; if ($authid_count > 55) {print F $authid_count, $ok; push(@ok, "OK")} else {print F "$authid_count $warning<br>"};

############################################################################################################################################
print "\nMatching PerConsole Nonce...\n\n"; 

print F "<br><b>PerConsole Nonce Match:</b><br>"; if ($metldr_pcn eq $pcn_eid_convert and $pcn_eid3_convert eq $pcn_eid5_convert and $bootldr_pcn eq $metldr_pcn) { print F "Metldr, EID0, EID3, EID5 & Bootldr", $ok; push(@ok, "OK")} else { push(@danger, "Danger"); print F "$danger - $metldr_pcn<br>$pcn_eid_convert<br>$pcn_eid3_convert<br>$pcn_eid5_convert<br>$bootldr_pcn<br>";}

############################################################################################################################################
print "\nChecking dump for Corrupt Sequences...\n\n"; 

# seek($bin, 0x0, 0);
# local $/; use bytes; my $content3 = <$bin>;
# print F "<br><b>Corrupt Sequence Check: <br></b>"; 

# my @ffsequence; while($content3 =~ m/([^ÿ]ÿÿÿÿÿÿÿÿ[^ÿ])/g) { push @ffsequence, $1 }; 
# if (grep {defined($_)} @ffsequence) {print F "$_ - $danger"; push(@danger, "DANGER") foreach @ffsequence;} else {print F "Nothing Found! $ok"; push(@ok, "OK");}


$ra->add( '([^ÿ]ÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿÿ[^ÿ])' );
#$ra->add( '([^\0]\0{16}[^\0])' );
$regex = $ra->re; my @matches_x; my @matches_xoff; my @matches_cake;
seek($bin, 0x0, 0);read($bin, my $matches_x, 0xFFFFF0);
#$match = uc ascii_to_hex($match); 
while ($matches_x =~ m/($regex)/g){
    my $matches_x = $1;
    my $offset = $-[0] + 0x0;
	$offset = uc sprintf("%x",$offset);
    push @matches_x, "[$matches_x] found at offset: 0x$offset";
	push @matches_xoff, "Corruption found at offset: 0x$offset";
}
print F "<br><b>16 bit Corrupt Sequence Check:</b><br>"; 

@matches_xoff = grep {$_ ne "Corruption found at offset: 0x7BFFEF"} @matches_xoff;
@matches_xoff = grep {$_ ne "Corruption found at offset: 0xEBFFEF"} @matches_xoff;

if (grep {defined($_)} @matches_xoff) {print F "$_ - $danger<br>" foreach @matches_xoff; push(@danger, "DANGER")} else {print F "Nothing Found! $ok"; push(@ok, "OK")}

$ra->add( '([^ÿ]ÿÿÿÿÿÿÿÿ[^ÿ])' );
$regex = $ra->re; my @matches_ff; my @matches_xff;
seek($bin, 0x0, 0);read($bin, my $match_ff, 0xFFFFF0);
#$match = uc ascii_to_hex($match); 
while ($match_ff =~ m/($regex)/g){
    my $match_ff = $1;
    my $offset = $-[0];
	$offset = uc sprintf("%x",$offset);
    push @matches_ff, "[$match_ff] found at offset: 0x$offset ";
	push @matches_xff, "Corruption found at offset: 0x$offset";
}
print F "<br><b>8 bit Corrupt Sequence Check:</b><br>"; 
if (grep {defined($_)} @matches_xff) {print F "$_ - $danger<br>" foreach @matches_xff; push(@danger, "DANGER")} else {print F "Nothing Found! $ok"; push(@ok, "OK")}

####################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################
print "\nChecking dump for Repetition...\n\n"; 

$ra->add( '000000000FACE0FF00000000DEADBEEF' );
$ra->add( '49464900000000010000000200000000' );
$ra->add( '000000010000000B0000000000EFFC00' );
$ra->add( '0000000000000400000000000002E800' );
$ra->add( '617365637572655F6C6F616465720000' );
$ra->add( '000000000002EC000000000000010000' );
$ra->add( '65454944000000000000000000000000' );
$ra->add( '000000000003EC000000000000000800' );
$ra->add( '63495344000000000000000000000000' );
$ra->add( '000000000003F4000000000000000800' );
$ra->add( '63435344000000000000000000000000' );
$ra->add( '000000000003FC000000000000020000' );
$ra->add( '7472766B5F7072673000000000000000' );
$ra->add( '000000000005FC000000000000020000' );
$ra->add( '7472766B5F7072673100000000000000' );
$ra->add( '000000000007FC000000000000020000' );
$ra->add( '7472766B5F706B673000000000000000' );
$ra->add( '000000000009FC000000000000020000' );
$ra->add( '7472766B5F706B673100000000000000' );
$ra->add( '00000000000BFC000000000000700000' );
$ra->add( '726F7330000000000000000000000000' );
$ra->add( '00000000007BFC000000000000700000' );
$ra->add( '726F7331000000000000000000000000' );
$ra->add( '0000000000EBFC000000000000040000' );
$ra->add( '637674726D0000000000000000000000' );
$ra->add( '6D65746C647200000000000000000000' );
$ra->add( '0000000100000001000000000002E800' );
$ra->add( '07FF0000000000000000000000000000' );
$ra->add( '1FFF0000000000000000000000000000' );
$ra->add( '000000000FACE0FF00000000DEADFACE' );
$ra->add( '7F49444C00020060' );
$regex = $ra->re; my @matches_rep; my @matches_rep2;
seek($bin, 0x0, 0);read($bin, my $match_rep, 0xFFFFF0);
$match_rep = uc ascii_to_hex($match_rep); 
while ($match_rep =~ m/($regex)/g){
    my $match_rep = $1;
    my $offset = $-[0];
	$offset = uc sprintf("%x",$offset);
    push @matches_rep, "[$match_rep] found at offset: 0x$offset ";
    push @matches_rep2, "$match_rep";
}
print F "<br><b>Repetition Check:</b><br>"; 

my $rep_count = grep {defined $_} @matches_rep;
# if ($rep_count > 31) {print F "$_ - $danger"; push(@danger, "DANGER") foreach @matches_rep;} else {print F "Nothing Found! $ok"; push(@ok, "OK");}

if ($rep_count > 31) {
my %seen;
foreach my $string (@matches_rep2) {
    next unless $seen{$string}++;
    print F "'$string' - $danger"; push(@danger, "DANGER");
}} else {print F "Nothing Found! $ok"; push(@ok, "OK");}

####################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################################

print "\nConfirming Statistics...\n\n"; 

print F "<br><b>00 / FF / Other Statistics:</b><br>".$calc00."%"; if ($calc00 < 18.38) { print F " $warning - Patch & Recheck (Risky below 18.24)<br>"; push(@warning, "WARNING")} elsif ($calc00 < 18.23) { print F " $danger <br>";} elsif ($calc00 > 29.01) { print F " $danger <br>"; push(@danger, "DANGER");} else { print F $ok; push(@ok, "OK");} print F $calcFF."%"; if ($calcFF < 10.41) { print F " $danger <br>"; push(@danger, "DANGER");} elsif ($calcFF > 10.48) { print F " $danger <br>"; push(@danger, "DANGER");} else { print F $ok; push(@ok, "OK");} print F $calcOther."%"; if ($calcOther > 0.50) { print F " $danger <br>"; push(@danger, "DANGER");} else { print F $ok; push(@ok, "OK");} 


############################################################################################################################################

print F "<br><br><b>Time to calculate:</b> ", Time::HiRes::tv_interval($start_time)," seconds.<br>",;
print F "<div style = \"text-align:right; float:right\"><a href=\"#Top\">Return</a></div><br>";

close(F); print "\nDone!\n\n"; 

# my $goodtxt = (colored ['bold green'], "OK: ");
# my $badtxt = (colored ['bold red'], "Danger: ");
# my $warningtxt = (colored ['bold yellow'], "Warning: ");
print "=======================================================================\n\n";

print "Quick Results:\n\n";
my $countgood = @ok;
my $countbad = @danger;
my $countwarning = @warning;
print "OK: $countgood\n";
print "Warning: $countwarning\n";
print "Danger: $countbad\n";

FAILURE:
use Term::ReadKey;      END { ReadMode ('restore'); }
$|=1;
my $char = "";
print "\n\nPress Enter to Exit: ";
binmode STDIN;
ReadMode ('cbreak');
while  (not defined (my $ch = ReadKey ())) 
{
	## Nothing to do but wait.
}
ReadMode ('restore');
$| = 0; 
if ( @files == 0 ) {} elsif (-e $original."_results.html") {
my $opensysfile = system($original."_results.html");}
elsif (-e $file."_results.html") {
my $opensysfile = system($file."_results.html");}
