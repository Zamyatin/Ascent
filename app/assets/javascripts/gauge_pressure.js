var barometer;

var loadBarometer = function(seriesData){
  barometer = new Highcharts.Chart({
      chart: {
        type: 'solidgauge',
        renderTo: 'gauge_3',
        plotBorderWidth: 0,
        spacingTop: 0,
        spacingLeft: 0,
        spacingRight: 0,
        spacingBottom: 0
      },

      title: {
        text: 'Barometer'
      },
      pane: {
        center: ['50%', '65%'],
        size: '100%',
        startAngle: -90,
        endAngle: 90,
        background: {
          backgroundColor: (Highcharts.theme && Highcharts.theme.background2) || '#EEE',
          innerRadius: '60%',
          outerRadius: '100%',
          shape: 'arc'
        }
      },
      tooltip: {
        enabled: false
      },
      yAxis: {
        stops: [
            [0.1, '#555555'],
            [0.5, '#888888'],
            [0.9, '#BBBBBB']
        ],
        lineWidth: 0,
        tickPixelInterval: 400,
        minorTickInterval: null,
        tickPixelInterval: 100,
        tickWidth: 0,
        labels: {
          y: 16,
          style: {color: '#ffffff'}
        },
        min: .001,
        max: 1100
      },
      plotOptions: {
        solidgauge: {
          animation: true,
          dataLabels: {
            y: 5,
            borderWidth: 0,
            useHTML: true
          }
        }
      },
      credits: {
        enabled: false
      },
      series: [{
        name: 'Pressure',
        data: [seriesData],
        dataLabels: {
          verticalAlign: 'middle',
          formatter: function() {
            var mbar = Math.round(this.y)
            return '<div style="text-align:center"><span style="font-size:25px;color:' +
                ((Highcharts.theme && Highcharts.theme.contrastTextColor) || 'black') + '">' + mbar + '</span><br/>' +
                   '<span style="font-size:14px;color:silver">mb</span></div>'
          }
        }
      }]
  });
};

var playBarometer = function(point) {
  barometer.series[0].points[0].update(point.pressure);
};
