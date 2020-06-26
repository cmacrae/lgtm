{{ define "mr-table" }}
<table class="table table-bordered">
  <thead>
    <th scope="col">Author</th>
    <th scope="col">Merge Request</th>
    <th scope="col">Votes</th>
  </thead>
  <tbody>
    {{range $mr := .}}
    <tr>
      <th style="vertical-align:middle" scope="row"><center><figure class="figure"><img class="figure-img img-fluid rounded" width="50" height="50" src="{{$mr.Author.AvatarURL}}" alt="{{$mr.Author.Name}}"><span class="d-none d-lg-block"><figcaption class="figure-caption text-center"><code>@{{$mr.Author.Username}}</code></figcaption></span></figure></center></th>
      <td style="vertical-align:middle">
	<b><a href="{{$mr.WebURL}}"
	      data-toggle="tooltip"
	      data-placement="top"
	      data-html="true"
	      title="<small>{{ deriveReference $mr.WebURL }}</small>"
	      target="_blank">{{trimWIP $mr.Title}}</a></b>
	<p>
	  {{- if $mr.WorkInProgress -}}
	  <span class="badge badge-warning">WIP</span>
	  {{end}}
	  {{range $mr.Labels}}<span class="badge badge-info">{{ . }}</span> {{end}}</p>
      </td>
      <td style="vertical-align:middle">
	<center>
	  {{ if $mr.WorkInProgress -}}
	  <button type="button" class="btn btn-light">
	    <span class="ec ec-construction"></span>
	  </button>
	  {{else}}
	  <button type="button" class="btn {{if lt $mr.Upvotes 2}}btn-light{{else}}btn-primary{{end}}">
	    <b>{{$mr.Upvotes}} </b><span class="ec ec-plus1"></span>
	  </button>
	  {{- end}}
	</center>
      </td>
    </tr>
    {{end}}
  </tbody>
</table>
{{ end }}

<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>LGTM | {{.Group.Name}} Merge Requests</title>

    <!-- JS -->
    <script src="https://code.jquery.com/jquery-3.4.1.slim.min.js" integrity="sha384-J6qa4849blE2+poT4WnyKhv5vZF5SrPo0iEjwBvKU7imGFAV0wwj1yYfoRSJoZ+n" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js" integrity="sha384-Q6E9RHvbIyZFJoft+2mJbHaEWldlvI9IOYy5n3zV9zzTtmI3UksdQRVvoxMfooAo" crossorigin="anonymous"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/js/bootstrap.min.js" integrity="sha384-wfSDF2E50Y2D1uUdj0O3uMBJnjuUD4Ih7YwaYd1iqfktj0Uod8GCExl3Og8ifwB6" crossorigin="anonymous"></script>

    <!-- Initialise tooltips -->
    <script>
      $(function () {
	  $('[data-toggle="tooltip"]').tooltip()
      })
    </script>

    <!-- Styles -->
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css" integrity="sha384-Vkoo8x4CGsO3+Hhxv8T/Q5PaXtkKtu6ug5TOeNV6gBiFeWPGFN9MuhOf23Q9Ifjh" crossorigin="anonymous">
    <link rel="stylesheet" type="text/css" href="/static/style.css">
    <link rel="stylesheet" type="text/css" href="/static/navigation_bar.css">
    <link rel='stylesheet' type="text/css" href='https://unpkg.com/emoji.css/dist/emoji.min.css'>

    <!-- Favicons -->
    <link rel="icon" type="image/x-icon" href="/favicon.ico">
    <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">
    <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">

  </head>

  <body>
    <div class="container">
      <div class="page-header">
	<h2><img class="figure-img img-fluid rounded" width="35" height="35" src="{{.Group.AvatarURL}}" alt="{{.Group.Name}}"> {{.Group.Name}} Merge Requests</h2>
      </div>
      <ul class="nav nav-tabs">
	<li class="nav-item">
	  <a href="#fresh" class="nav-link active" data-toggle="tab">
	    <span class="ec ec-sparkles"></span> <b>Fresh</b> <span class="badge badge-secondary" data-toggle="tooltip" data-title="MRs opened within the last 2 weeks">{{len .OpenMRs.Fresh}}</span>
	  </a>
	</li>
	<li class="nav-item">
	  <a href="#stale" class="nav-link" data-toggle="tab">
	    <span class="ec ec-lying-face"></span> <b>Stale</b> <span class="badge badge-secondary" data-toggle="tooltip" data-title="MRs opened more than 2 weeks ago">{{len .OpenMRs.Stale}}</span>
	  </a>
	</li>
      </ul>
      <div class="tab-content">
	<div class="tab-pane fade show active" id="fresh">
	  {{ template "mr-table" .OpenMRs.Fresh }}
	</div>
	<div class="tab-pane fade" id="stale">
	  {{ template "mr-table" .OpenMRs.Stale }}
	</div>
      </div>
    </div>
  </body>
</html>
