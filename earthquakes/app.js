// Generated by CoffeeScript 1.3.3
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  require(['jquery', 'd3'], function($, d3) {
    var Earthquakes, getParams, start;
    getParams = function() {
      return {
        p: window.location.hash.substr(1)
      };
    };
    Earthquakes = (function() {

      Earthquakes.prototype.c = {
        width: 1024,
        height: 580
      };

      function Earthquakes() {
        this.onDataPaths = __bind(this.onDataPaths, this);

        this.onDataCircles = __bind(this.onDataCircles, this);

        this.renderAt = __bind(this.renderAt, this);

        this.animateEarthquakes = __bind(this.animateEarthquakes, this);

        this.drawCountries = __bind(this.drawCountries, this);

        this.drawSlider = __bind(this.drawSlider, this);

        this.redraw = __bind(this.redraw, this);

        this.onMouseUp = __bind(this.onMouseUp, this);

        this.onMouseMove = __bind(this.onMouseMove, this);

        this.onMouseDown = __bind(this.onMouseDown, this);

        var origin,
          _this = this;
        this.date = d3.select('h2');
        this.svg = d3.select('body').append('svg').attr('width', this.c.width).attr('height', this.c.height).on('mousedown', this.onMouseDown);
        if (getParams().p) {
          origin = getParams().p.split(',').map(function(p) {
            return parseFloat(p);
          });
        } else {
          origin = [-71.03, 42.37];
        }
        this.projection = d3.geo.azimuthal().scale(250).origin(origin).mode('orthographic').translate([this.c.width / 2, this.c.height / 2]);
        this.path = d3.geo.path().projection(this.projection).pointRadius(3);
        this.circle = d3.geo.greatCircle().origin(this.projection.origin());
        d3.select(window).on('mousemove', this.onMouseMove).on('mouseup', this.onMouseUp);
        this.clip = function(d) {
          return _this.path(_this.circle.clip(d));
        };
        this.countries_g = this.svg.append('svg:g').attr('class', 'countries');
        this.drawCountries();
        this.earthquakes_g = this.svg.append('svg:g').attr('class', 'earthquakes');
      }

      Earthquakes.prototype.m0 = null;

      Earthquakes.prototype.o0 = null;

      Earthquakes.prototype.onMouseDown = function() {
        this.m0 = [d3.event.pageX, d3.event.pageY];
        this.o0 = this.projection.origin();
        return d3.event.preventDefault();
      };

      Earthquakes.prototype.onMouseMove = function() {
        var m0, m1, o0, o1;
        if (this.m0) {
          m0 = this.m0;
          o0 = this.o0;
          m1 = [d3.event.pageX, d3.event.pageY];
          o1 = [o0[0] + (m0[0] - m1[0]) / 8, o0[1] + (m1[1] - m0[1]) / 8];
          window.location.hash = o1;
          this.projection.origin(o1);
          this.circle.origin(o1);
          return this.redraw();
        }
      };

      Earthquakes.prototype.onMouseUp = function() {
        if (this.m0) {
          this.onMouseMove();
          return this.m0 = null;
        }
      };

      Earthquakes.prototype.redraw = function(duration) {
        var circle,
          _this = this;
        if (duration) {
          return this.countries.transition().duration(duration).attr('d', this.clip);
        } else {
          this.countries.attr('d', this.clip);
          circle = this.circle;
          return this.earthquakes.attr('cx', function(d) {
            return _this.projection(d.geometry.coordinates.slice(0, 2))[0];
          }).attr('cy', function(d) {
            return _this.projection(d.geometry.coordinates.slice(0, 2))[1];
          }).attr('r', function(d) {
            if (circle.clip(d)) {
              return d3.select(this).attr('r');
            } else {
              return 0;
            }
          });
        }
      };

      Earthquakes.prototype.drawSlider = function(extents) {
        var renderAt;
        renderAt = this.renderAt;
        return this.slider = d3.select('body').append('input').attr('class', 'timeslider').attr('type', 'range').attr('min', extents[0]).attr('max', extents[1]).attr('value', extents[1]).attr('step', 1).on('change', function() {
          return renderAt(this.value);
        });
      };

      Earthquakes.prototype.drawCountries = function() {
        var _this = this;
        return d3.json('/data/world-countries.json', function(collection) {
          return _this.countries = _this.countries_g.selectAll('path').data(collection.features).enter().append('svg:path').attr('d', _this.clip);
        });
      };

      Earthquakes.prototype.animateEarthquakes = function(data) {
        this.features = data.features;
        return this.onDataCircles(this.features);
      };

      Earthquakes.prototype.renderAt = function(time) {
        var entered, es, exited, features,
          _this = this;
        this.date.html(new Date(time * 1000).toString());
        features = this.features.filter(function(d) {
          return d.properties.time <= time;
        });
        es = this.earthquakes_g.selectAll('circle').data(features);
        exited = es.exit();
        exited.remove();
        entered = es.enter();
        return entered.append('svg:circle').attr('r', 0).attr('cx', function(d) {
          return _this.projection(d.geometry.coordinates.slice(0, 2))[0];
        }).attr('cy', function(d) {
          return _this.projection(d.geometry.coordinates.slice(0, 2))[1];
        }).transition().duration(this.c.durations["in"]).attr('r', function(d) {
          if (_this.circle.clip(d)) {
            return 0.0001 * Math.pow(10, d.properties.mag);
          } else {
            return 0;
          }
        }).transition().duration(this.c.durations.out).delay(this.c.durations["in"]).attr('r', function(d) {
          if (_this.circle.clip(d)) {
            return d.properties.mag;
          } else {
            return 0;
          }
        });
      };

      Earthquakes.prototype.onDataCircles = function(features) {
        var durations, entered, extent,
          _this = this;
        this.earthquakes = this.earthquakes_g.selectAll('circle').data(features, function(d) {
          return d.id;
        });
        this.c.durations = {
          "in": 200,
          out: 200,
          spacing: 25,
          length: 15000
        };
        durations = this.c.durations;
        extent = d3.extent(features, function(d) {
          return d.properties.time;
        });
        this.drawSlider(extent);
        this.timeScale = d3.scale.linear().domain(extent).range([0, durations.length]);
        return entered = this.earthquakes.enter().append('svg:circle').attr('r', 0).attr('cx', function(d) {
          return _this.projection(d.geometry.coordinates.slice(0, 2))[0];
        }).attr('cy', function(d) {
          return _this.projection(d.geometry.coordinates.slice(0, 2))[1];
        }).transition().duration(durations["in"]).delay(function(d, i) {
          return _this.timeScale(d.properties.time);
        }).attr('r', function(d) {
          if (_this.circle.clip(d)) {
            return 0.0001 * Math.pow(10, d.properties.mag);
          } else {
            return 0;
          }
        }).transition().duration(durations.out).delay(function(d, i) {
          return _this.timeScale(d.properties.time) + durations["in"];
        }).attr('r', function(d) {
          if (_this.circle.clip(d)) {
            return d.properties.mag;
          } else {
            return 0;
          }
        }).each('end', function(d) {
          _this.date.html(new Date(d.properties.time * 1000).toString());
          return _this.slider.attr('value', d.properties.time);
        });
      };

      Earthquakes.prototype.onDataPaths = function(data) {
        var entered;
        this.earthquakes = this.earthquakes_g.selectAll('path').data(data.features);
        return entered = this.earthquakes.enter().append('svg:path').attr('d', this.clip);
      };

      return Earthquakes;

    })();
    start = function() {
      window.earthquakes = new Earthquakes;
      window.eqfeed_callback = earthquakes.animateEarthquakes;
      return $.ajax({
        url: 'http://earthquake.usgs.gov/earthquakes/feed/geojsonp/2.5/month',
        dataType: 'jsonp'
      });
    };
    return $(function() {
      return start();
    });
  });

}).call(this);
