package engine

const (
	DASHBOARD_TPL = `
<html>
<head>
<title>{{ .Title }}</title>
<meta http-equiv="refresh" content="10">
<script src="http://cdnjs.cloudflare.com/ajax/libs/jquery/2.0.3/jquery.min.js"></script>
<script src="http://cdnjs.cloudflare.com/ajax/libs/flot/0.8.2/jquery.flot.min.js"></script>
<script src="http://cdnjs.cloudflare.com/ajax/libs/flot/0.8.2/jquery.flot.time.min.js"></script>
<script src="http://cdnjs.cloudflare.com/ajax/libs/flot/0.8.2/jquery.flot.selection.min.js"></script>

<script type="text/javascript">
	var calls = {{ .Calls }};
	var sessions = {{ .Sessions }};
	var data = [
			{ label: "slow", data: {{ .Slows }} },	
    		{ label: "conns", data: {{ .ActiveSessions }} },
    		{ label: "err", data: {{ .Errors }} },
    		{ label: "qps2", data: {{ .Qps }}, yaxis: 2 },
    		{ label: "latency", data: {{ .Latencies }} },
	];

	var mem = [
			{ label: "NumGC2", data: {{ .NumGC }}, yaxis: 2 },
			{ label: "HeapSys", data: {{ .HeapSys }} },
			{ label: "HeapAlloc", data: {{ .HeapAlloc }} },
			{ label: "HeapReleased2", data: {{ .HeapReleased }}, yaxis: 2 },	
			{ label: "StackInUse2", data: {{ .StackInUse }}, yaxis: 2 },
	];
	var heapObjects = [
			{ label: "HeapObjects", data: {{ .HeapObjects }} },
	];
	var gcPause = [
			{ label: "GcPause100/us", data: {{ .GcPause100 }} },
			{ label: "GcPause99/us", data: {{ .GcPause99 }} },
			{ label: "GcPause95/us", data: {{ .GcPause95 }} },
	];

	var options = {
		legend: {
			position: "nw",
			noColumns: 5,
			backgroundOpacity: 0.2
		},
		xaxis: {
			mode: "time",
			timezone: "browser",
			timeformat: "%H:%M:%S "
		},
		yaxes: [
			{},
			{
				position: "right",
			}
		],
		selection: {
			mode: "x"
		},
	};

	var options_mem = {
		legend: {
			position: "nw",
			noColumns: 6,
			backgroundOpacity: 0.2
		},
		xaxis: {
			mode: "time",
			timezone: "browser",
			timeformat: "%H:%M:%S "
		},		
		yaxes: [
			{},
			{
				position: "right",
			}
		],		
	};

	var options_gc = {
		legend: {
			position: "nw",
			noColumns: 6,
			backgroundOpacity: 0.2
		},
		xaxis: {
			mode: "time",
			timezone: "browser",
			timeformat: "%H:%M:%S "
		},		
		yaxes: [
			{},
			{
				position: "right",
			}
		],
		points: { show: true },
		lines: { show: true, fill: true },
		yaxis: {tickFormatter: function numberWithCommas(x) {
            return x.toString().replace(/\B(?=(?:\d{3})+(?!\d))/g, ",");
        }},
	};

	$(document).ready(function() {
		var plot = $.plot("#placeholder", data, options);
		var plotmem = $.plot("#placeholder_mem", mem, options_mem);
		var heapobj = $.plot("#placeholder_heapobj", heapObjects, options_mem);
		var gcpause = $.plot("#placeholder_gcpause", gcPause, options_mem);
	});

	$(document).ready(function() {
		var plot = $.plot("#placeholder", data, options);
		var plotmem = $.plot("#placeholder_mem", mem, options_mem);
		var heapobj = $.plot("#placeholder_heapobj", heapObjects, options_gc);
		var gcpause = $.plot("#placeholder_gcpause", gcPause, options_gc);
	});	
</script>
<style>
#content {
	margin: 0 auto;
	padding: 10px;
}

.demo-container {
	box-sizing: border-box;
	width: 1200px;
	height: 450px;
	padding: 20px 15px 15px 15px;
	margin: 15px auto 30px auto;
	border: 1px solid #ddd;
	background: #fff;
	background: linear-gradient(#f6f6f6 0, #fff 50px);
	background: -o-linear-gradient(#f6f6f6 0, #fff 50px);
	background: -ms-linear-gradient(#f6f6f6 0, #fff 50px);
	background: -moz-linear-gradient(#f6f6f6 0, #fff 50px);
	background: -webkit-linear-gradient(#f6f6f6 0, #fff 50px);
	box-shadow: 0 3px 10px rgba(0,0,0,0.15);
	-o-box-shadow: 0 3px 10px rgba(0,0,0,0.1);
	-ms-box-shadow: 0 3px 10px rgba(0,0,0,0.1);
	-moz-box-shadow: 0 3px 10px rgba(0,0,0,0.1);
	-webkit-box-shadow: 0 3px 10px rgba(0,0,0,0.1);
}

.demo-placeholder {
	width: 100%;
	height: 100%;
	font-size: 14px;
	line-height: 1.2em;
}
</style>
</head>
<body>
<div id="peers">
  <p>Cluster: 
  {{range $index, $peer := .Peers}}<a href="http://{{$peer}}">{{$peer}}</a>&nbsp;&nbsp;
  {{end}}</p>
</div>

<div id="content">
	<p>Memory Presure</p>
	<div class="demo-container" style="height:200px;">		
		<div id="placeholder_mem" class="demo-placeholder"></div>
	</div>
	<p>GC Pause Percentiles</p>
	<div class="demo-container" style="height:200px;">		
		<div id="placeholder_gcpause" class="demo-placeholder"></div>
	</div>
	<p>Heap Objects In Use</p>
	<div class="demo-container" style="height:200px;">		
		<div id="placeholder_heapobj" class="demo-placeholder"></div>
	</div>
	<p>RPC call</p>
	<div class="demo-container" style="height:400px;">		
		<div id="placeholder" class="demo-placeholder"></div>
	</div>	
</div>

</body>
</html>
	`
)
