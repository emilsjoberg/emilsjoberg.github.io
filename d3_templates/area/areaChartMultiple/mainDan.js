var margin = {top: 10, right: 40, bottom: 150, left: 60},
	width = 940 - margin.left - margin.right,
	height - 500 - margin.top - margin.bottom,
	contextHeight = 50;
	contextWidth = width * .5;

var svg = d3.select("#chart-container")
	.append("svg")
		.attr("width", width + margin.left + margin.right)
		.attr("height", (height + margin.top + margin.bottom));

d3.csv('data.csv', createChart);

function