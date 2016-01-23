#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Mojolicious::Lite;
use Encode;

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

my $regexp = qr/([\x{007f}-\x{00a4}\x{00a6}\x{00aa}-\x{00af}\x{00b2}-\x{00b3}\x{00b5}\x{00b7}-\x{00d6}\x{00d8}-\x{00f6}\x{00f8}-\x{0390}\x{03a2}\x{03aa}-\x{03b0}\x{03c2}\x{03ca}-\x{0400}\x{0402}-\x{040f}\x{0450}\x{0452}-\x{200f}\x{2012}-\x{2014}\x{2016}-\x{2017}\x{201a}-\x{201b}\x{201e}-\x{201f}\x{2022}-\x{2025}\x{2028}-\x{202f}\x{2031}\x{2034}-\x{203a}\x{203c}-\x{215f}\x{216a}-\x{216f}\x{217a}-\x{218f}\x{2194}-\x{21d1}\x{21d3}\x{2135}-\x{21ff}\x{2201}\x{2204}-\x{2206}\x{2209}-\x{220a}\x{220c}-\x{2210}\x{2212}-\x{2219}\x{221b}-\x{221c}\x{2221}-\x{2224}\x{2226}\x{222d}\x{222f}-\x{2233}\x{2236}-\x{223c}\x{223e}-\x{2251}\x{2253}-\x{225f}\x{2262}-\x{2265}\x{2268}-\x{2269}\x{226c}-\x{2281}\x{2284}-\x{2285}\x{2288}-\x{22a4}\x{22a6}-\x{22be}\x{22c0}-\x{22ff}\x{2474}-\x{24ff}\x{2504}-\x{250b}\x{250d}-\x{250e}\x{2511}-\x{2512}\x{2515}-\x{2516}\x{2519}-\x{251a}\x{251e}-\x{251f}\x{2521}-\x{2522}\x{2526}-\x{2527}\x{2529}-\x{252a}\x{252d}-\x{252e}\x{2531}-\x{2532}\x{2535}-\x{2536}\x{2539}-\x{253a}\x{253d}-\x{253e}\x{2540}-\x{2541}\x{2543}-\x{254a}\x{254c}-\x{257f}\x{25a2}-\x{25b1}\x{25b4}-\x{25bb}\x{25be}-\x{25c5}\x{25c8}-\x{25c9}\x{25cc}-\x{25cd}\x{25d0}-\x{25ee}\x{25f0}-\x{25ff}])/;

sub parse_from_data {
    my ($data, $type) = @_;
    $data //= '';

    my @lines = map { chomp($_); $_ } split(/\n/, $data);

    return parse_lines(\@lines, $type);
}

sub parse_from_file {
    my ($uploaded, $type) = @_;
    my $data = $uploaded->slurp;
    unless ( utf8::is_utf8($data) ) {
        $data = Encode::decode('utf8', $data);
    }
    return parse_from_data( $data, $type );
}

sub parse_lines {
    my ($lines, $type) = @_;

    my $counter = 0;
    my @result = map {
        my @invalid_chars = invalid_char($_);
        ++$counter;
        scalar @invalid_chars
            ? {
                line => $counter,
                data => create_view($_, \@invalid_chars),
                chars => join(',', @invalid_chars),
            }
            : ();
    } @$lines;
    return \@result;
}

sub invalid_char {
    my ($line) = @_;

    return $line =~ m|$regexp|g;
}

sub create_view {
    my ($str, $invalid_chars) = @_;

    foreach my $char (@$invalid_chars) {
        my $replace = sprintf ' _%s_ ', $char;
        $str =~ s/$char/$replace/g
    }
    return $str;
}


get '/' => sub {
    my $c = shift;
    $c->render(template => 'index');
};

post '/post_data' => sub {
    my $c = shift;
    $c->render(
        template => 'view',
        results  => parse_from_data($c->param('data'), $c->param('type')),
    );
};

post '/post_file' => sub {
    my $c = shift;
    my $uploaded = $c->param('file');
    $c->render(
        template => 'view',
        results  => parse_from_file($uploaded, $c->param('type')),
    );
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title '文字チェッカー';
<h1><%= title %></h1>

<h2>ファイルから</h2>
<form method="post" action="/post_file" class="form-horizontal" role="form" enctype="multipart/form-data">
    <div class="form-group">
        <div class="col-sm-offset-1 col-sm-10">
            <input type="radio" name="type" class="" id="etaxFile" checked="checked" /><label for="etaxFile">国税</label>
            <input type="radio" name="type" class="" id="eltaxFile" /><label for="eltaxFile">地方税</label>
        </div>
    </div>
    <div class="form-group">
        <div class="col-sm-offset-1 col-sm-10">
            <input type="file" name="file" class="form-control" />
        </div>
    </div>

    <div class="form-group">
        <div class="col-sm-offset-1 col-sm-10">
            <button type="submit" class="btn btn-primary">送信</button>
        </div>
    </div>
</form>

<h2>フォームから</h2>
<form method="post" action="/post_data" class="form-horizontal" role="form">
    <div class="form-group">
        <div class="col-sm-offset-1 col-sm-10">
            <input type="radio" name="type" class="" id="etaxData" checked="checked" /><label for="etaxData">国税</label>
            <input type="radio" name="type" class="" id="eltaxData" /><label for="eltaxData">地方税</label>
        </div>
    </div>
    <div class="form-group">
        <div class="col-sm-offset-1 col-sm-10">
            <textarea class="form-control" name="data" rows="40" placeholder="データを入力してください"></textarea>
        </div>
    </div>

    <div class="form-group">
        <div class="col-sm-offset-1 col-sm-10"> <button type="submit" class="btn btn-primary">送信</button> </div>
    </div>
</form>

@@ view.html.ep
% layout 'default';
% title '文字チェッカー';
<h1><%= title %></h1>

<h2>結果</h2>

<div class="panel panel-default">
    <!-- Table -->
    <table class="table">
        <tr>
            <th class="col-sm-1">Line</th>
            <th class="col-sm-7">Data</th>
            <th class="col-sm-2">Invalid</th>
        </tr>
        % for my $row (@$results) {
        <tr>
            <td class="col-sm-1"><%= $row->{line} %></td>
            <td class="col-sm-7"><%= $row->{data} %></td>
            <td class="col-sm-2"><%= $row->{chars} %></td>
        </tr>
        % }
    </table>
</div>



@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><%= title %></title>
<link rel="stylesheet" href="/bootstrap/css/bootstrap.css" />
</head>
<body>
<div class="container">
<%= content %>
</div>
</body>
</html>
