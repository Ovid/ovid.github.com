/*

Very, very loosely based on: http://www.soa-world.de/echelon/2008/07/fourth-prototype.html

Copyright (c) 2008 Sebastian Schaetz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/


var PI2 = Math.PI * 2;

var renderer = {
    canvas:             null,
    ctx:                null,
    canvas_offset_left: 0,
    canvas_offset_top:  0,
    initialize: function(mapname) {
        this.canvas             = $(mapname);
        this.ctx                = this.canvas.getContext("2d");
        this.canvas_offset_left = Element.viewportOffset(this.canvas).left;
        this.canvas_offset_top  = Element.viewportOffset(this.canvas).top;
    },
    clear_canvas: function() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    },
    draw_circle: function(x, y, radius, rgb) {
        var ctx  = this.ctx;
        ctx.fillStyle = 'rgb(' + rgb + ')';
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, PI2, false);
        ctx.fill();
    },
    draw_current: function( x, y ) {
        var ctx = this.ctx;
        ctx.strokeStyle = "rgb(0,255,0)";
        ctx.beginPath();
        // XXX hardcoded radius. Yuck
        ctx.arc(x, y, 8, 0, PI2, true);
        ctx.stroke();
    },
    draw_line: function(from_x, from_y, to_x, to_y, color) {
        var ctx = this.ctx;
        ctx.strokeStyle = "rgb("+color+")";
        ctx.beginPath();
        ctx.moveTo(from_x, from_y);
        ctx.lineTo(to_x,   to_y);
        ctx.stroke();
    },
    draw_text: function(text, x, y, size) {
        var ctx  = this.ctx;
        ctx.font = size + "px Arial";
        ctx.fillText(text, x, y);
    }
};

// only one instance of the map
var map = {
    star_radius:      2,
    stars:            [],
    wormholes:        [],
    show_wormholes:   true,
    show_names:       true,
    show_unreachable: true,
    rotate_angle:     0.01,                // angle per rotation in radians
    zscale:           600,                 // value for projecting stars onto canvas
    zhelper:          255 / 600,           // value for depth fading
    loop_timeout:     10,
    degree:           0,                   // angle of rotation in radians
    selected:         -1,                  // indicates which star is selected
    direction:        0,                   // direction of rotation (x is 1, y is 2, z is 3)
    is_moving:        false,               // but will be set to true on load
    renderer:         renderer,
    initialize:       function(canvas_name) {
        this.renderer.initialize(canvas_name);
        this.load_stars();

        // start continous rotation around y axis
        this.rotate_stars(2);
    },
    draw: function(redraw) {
        if (!this.is_moving && !redraw)
            return;
        this.renderer.clear_canvas();

        for(var i=0; i<this.stars.length; i++) {
            var star = this.stars[i];

            if(this.direction == 0) {
                // don't rotate
            }
            else if(this.direction == 1)
                star.rotate_x();
            else if(this.direction == 2)
                star.rotate_y();
            else if(this.direction == 3)
                star.rotate_z();

            star.project_star();  // calculate renderering coordinates
            this.draw_star(i, this.star_radius, star.projected_z + ',' + star.projected_z + ',' + star.projected_z);
        }

        // draw the selected star (if any)
        if(this.selected != -1) {
            this.draw_star(this.selected, this.star_radius + 1, '255,0,0');
        }

        if(this.show_wormholes) {
            var stars = this.stars;
            for(var i=0; i<this.wormholes.length; i++) {
                var wormhole = this.wormholes[i];
                this.draw_wormhole(stars[wormhole.from], stars[wormhole.to], wormhole.color);
            }
        }
        if(this.is_moving) {
            // http://stackoverflow.com/questions/1101668/how-to-use-settimeout-to-invoke-object-itself
            // Also, need to clear the last timeout first. Probably a better
            // way of doing this.
            var _this = this;
            if (this.last_timout) clearTimeout(this.last_timout);
            this.last_timout = setTimeout(function() { _this.draw() }, _this.loop_timeout);
        }
    },
    last_timout: null,
    toggle_wormholes: function() {
        if(this.show_wormholes)
            this.show_wormholes = false;
        else
            this.show_wormholes = true;
        this.draw(true);
    },
    last_rotation_status: true,
    stop_rotation: function() {
        this.last_rotation_status = this.is_moving;
        this.is_moving = false;
        this.degree    = 0;
    },
    restart_rotation: function() {
        // only restart if it was moving last time
        this.is_moving = this.last_rotation_status;
        if (this.is_moving) {
            this.rotate_stars(2);
        }
        this.draw();
    },
    toggle_rotation: function() {
        if(this.is_moving) {
            this.is_moving = false;
            this.degree = 0;
        }
        else {
            this.rotate_stars(2);
        }
        this.draw();
    },
    toggle_names: function() {
        if(this.show_names) {
            this.show_names = false;
        }
        else {
            this.show_names = true;
        }
        this.draw(true);
    },
    toggle_unreachable: function() {
        if(this.show_unreachable) {
            this.show_unreachable = false;
        }
        else {
            this.show_unreachable = true;
        }
        this.draw(true);
    },
    draw_star: function(index, radius, rgb) {
        var star = this.stars[index];
        if ( !this.show_unreachable && !star.reachable ) {
            return;
        }
        this.renderer.draw_circle(star.projected_x, star.projected_y, radius, rgb);
        if ( star.current ) {
            this.renderer.draw_current( star.projected_x, star.projected_y );
        }
        if ( this.show_names ) {

            // scale the text (larger when closer)
            size = parseInt( 10 * ( 7 + ( 7 * star.projected_z ) / 255 ) ) / 10;
            this.renderer.draw_text(star.name, star.projected_x - 20, star.projected_y - 5, size);
        }
    },
    draw_wormhole: function(from, to, color) {
        if ( !this.show_unreachable && !from.reachable ) {
            return;
        }
        this.renderer.draw_line(from.projected_x, from.projected_y, to.projected_x, to.projected_y, color);
    },
    rotate_stars: function(direction) {
        this.degree    = this.rotate_angle;
        this.direction = direction;
        if(!this.is_moving) {
            this.is_moving = true;
            this.draw();
        }
    },
    load_stars: function() {
        alert("You must override this function");
        /* examples
        this.stars[0] = new star( 0, 0, 0, "Sol  ", "G2", "8", "6", 1, 0 );
        this.stars[1] = new star( -23.1, -19.18, -53.76, "Alpha Centauri A", "G2", "6", "9", 1, 1 );
        this.stars[2] = new star( -23.1, -19.18, -53.76, "Alpha Centauri B", "K0", "0", "0", 0, 0 );

        // and later
        this.wormholes[0] = { from: 0, to: 1, color: "255,255,255" };
        if (!this.stars[0].reachable) this.wormholes[0].color = '0,255,255';
        this.wormholes[1] = { from: 0, to: 4, color: "0,0,235" };
        if (!this.stars[0].reachable) this.wormholes[1].color = '0,255,255';

        // and later
        this.draw();
        */
    },
    select_star: function(event) {
        var renderer = this.renderer;
        var x = Event.pointerX(event) - renderer.canvas_offset_left;
        var y = Event.pointerY(event) - renderer.canvas_offset_top;
        var dist = this.star_radius + 4;                     // click distance from star center
        this.selected = -1;
        $('star_id').update('No star selected');
        for(var i=0; i<this.stars.length; i++) {
            star = this.stars[i];
            if(star.projected_x > x-dist && star.projected_x < x+dist &&
               star.projected_y > y-dist && star.projected_y < y+dist)
            {
                this.selected = i;
                if (star.wormholes == 0) {
                    $('star_id').update("Name: "+star.name+'<br />Type: '+star.type);
                }
                else {
                    $('star_id').update(
                        "Name: "              + star.name
                        + '<br />Type: '      + star.type
                        + '<br />Wormholes: ' + star.wormholes
                        + '<br />Stations: '  + star.stations
                    );
                }
                break;
            }
        }
        this.draw(true);
    }
};

function star(x, y, z, name, type, num_wormholes, num_stations, reachable, current) {
    this.x         = x;
    this.y         = y;
    this.z         = z;
    this.name      = name;
    this.type      = type;
    this.wormholes = num_wormholes;
    this.stations  = num_stations;
    this.reachable = reachable;
    this.current   = current;

    this.projected_x = 0;
    this.projected_y = 0;
    this.projected_z = 0;

    // methods
    this.project_star = project_star;
    this.rotate_x     = rotate_x;
    this.rotate_y     = rotate_y;
    this.rotate_z     = rotate_z;

    function project_star() {
        this.projected_x = (renderer.canvas.width / 2)  + (this.x * map.zscale / (this.z + map.zscale));
        this.projected_y = (renderer.canvas.height / 2) + (this.y * map.zscale / (this.z + map.zscale));
        this.projected_z = 255 - Math.round((this.z + (map.zscale/2)) * map.zhelper);
    }

    // rotate star around x axis
    function rotate_x() {
        curr_sin = Math.sin(map.degree);
        curr_cos = Math.cos(map.degree);
        var y  = (this.y * curr_cos) + (this.z * (-curr_sin));
        this.z = (this.y * curr_sin) + (this.z * (curr_cos));
        this.y = y;
    }

    // rotate star around y axis
    function rotate_y() {
        curr_sin = Math.sin(map.degree);
        curr_cos = Math.cos(map.degree);
        var x  = (this.x * curr_cos) + (this.z * curr_sin);
        this.z = (this.x * (-curr_sin)) + (this.z * (curr_cos));
        this.x = x;
    }

    // rotate star around z axis
    function rotate_z() {
        curr_sin = Math.sin(map.degree);
        curr_cos = Math.cos(map.degree);
        var x  = (this.x * curr_cos) + (this.y * (-curr_sin));
        this.y = (this.x * curr_sin) + (this.y * (curr_cos));
        this.x = x;
    }
}


Event.observe(window, "load", function() {
    map.initialize('starmap');
    add_event_handlers();
    $('toggle_wormholes').checked   = true;
    $('toggle_rotation').checked    = true;
    $('toggle_names').checked       = true;
    $('toggle_unreachable').checked = true;
});

function add_event_handlers() {
    Event.observe($('toggle_wormholes'),   'click', function()      { map.toggle_wormholes(); });
    Event.observe($('toggle_rotation'),    'click', function()      { map.toggle_rotation(); });
    Event.observe($('toggle_names'),       'click', function()      { map.toggle_names(); });
    Event.observe($('toggle_unreachable'), 'click', function()      { map.toggle_unreachable(); });
    Event.observe(map.renderer.canvas,     'click', function(event) { map.select_star(event); });
    Event.observe(map.renderer.canvas,     'mouseover', function(event) {
        map.stop_rotation();
        $('toggle_rotation').checked = false;
    });
    Event.observe(map.renderer.canvas,     'mouseout', function(event) {
        map.restart_rotation();
        $('toggle_rotation').checked = map.is_moving;
    });
}
