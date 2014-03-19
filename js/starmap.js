/*

Very, very loosely based on: http://www.soa-world.de/echelon/2008/07/fourth-prototype.html

Need to add zoom and scrolling.

*/

var PI2 = Math.PI * 2;

var renderer = {
    canvas: null,
    ctx: null,
    canvas_offset_left: 0,
    canvas_offset_top: 0,
    initialize: function (mapname) {
        this.canvas = $(mapname);
        this.ctx = this.canvas.getContext("2d");
        this.canvas_offset_left = Element.viewportOffset(this.canvas).left;
        this.canvas_offset_top = Element.viewportOffset(this.canvas).top;
    },
    clear_canvas: function () {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    },
    draw_circle: function (x, y, radius, rgb) {
        var ctx = this.ctx;
        ctx.fillStyle = 'rgb(' + rgb + ')';
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, PI2, false);
        ctx.fill();
    },
    draw_line: function (from_x, from_y, to_x, to_y, color) {
        var ctx = this.ctx;
        ctx.strokeStyle = "rgb(" + color + ")";
        ctx.beginPath();
        ctx.moveTo(from_x, from_y);
        ctx.lineTo(to_x, to_y);
        ctx.stroke();
    },
    draw_text: function (text, x, y, size) {
        var ctx = this.ctx;
        ctx.font = size + "px Arial";
        ctx.fillText(text, x, y);
    }
};

function star(x, y, z, name, type, num_wormholes, num_stations, reachable) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.name = name;
    this.type = type;
    this.wormholes = num_wormholes;
    this.stations = num_stations;
    this.reachable = reachable;

    this.projected_x = 0;
    this.projected_y = 0;
    this.projected_z = 0;

    // methods
    this.project_star = project_star;
    this.rotate_x = rotate_x;
    this.rotate_y = rotate_y;
    this.rotate_z = rotate_z;

    function project_star() {
        this.projected_x = (renderer.canvas.width / 2) + (this.x * map.zscale / (this.z + map.zscale));
        this.projected_y = (renderer.canvas.height / 2) + (this.y * map.zscale / (this.z + map.zscale));
        this.projected_z = 255 - Math.round((this.z + (map.zscale / 2)) * map.zhelper);
    }

    // rotate star around x axis
    function rotate_x() {
        curr_sin = Math.sin(map.degree);
        curr_cos = Math.cos(map.degree);
        var y = (this.y * curr_cos) + (this.z * (-curr_sin));
        this.z = (this.y * curr_sin) + (this.z * (curr_cos));
        this.y = y;
    }

    // rotate star around y axis
    function rotate_y() {
        curr_sin = Math.sin(map.degree);
        curr_cos = Math.cos(map.degree);
        var x = (this.x * curr_cos) + (this.z * curr_sin);
        this.z = (this.x * (-curr_sin)) + (this.z * (curr_cos));
        this.x = x;
    }

    // rotate star around z axis
    function rotate_z() {
        curr_sin = Math.sin(map.degree);
        curr_cos = Math.cos(map.degree);
        var x = (this.x * curr_cos) + (this.y * (-curr_sin));
        this.y = (this.x * curr_sin) + (this.y * (curr_cos));
        this.x = x;
    }
}

// only one instance of the map
var map = {
    star_radius: 2, // the radius of the stars
    stars: [], // array containing the stars
    wormholes: [], // array containing the wormhole [from_star_id, to_star_id]
    show_wormholes: true,
    show_names: true,
    show_unreachable: true,
    rotate_angle: 0.01, // angle per rotation in radians
    zscale: 600, // value for projecting stars onto canvas
    zhelper: 255 / 600, // value for depth fading
    loop_timeout: 10, // timeout between rotations in ms
    degree: 0, // angle of rotation in radians
    selected: -1, // indicates which star is selected
    direction: 0, // direction of rotation (x is 1, y is 2, z is 3)
    is_moving: false, // but will be set to true on load
    renderer: renderer,
    initialize: function (canvas_name) {
        this.renderer.initialize(canvas_name);
        this.load_stars();

        // start continous rotation around y axis
        this.rotate_stars(2);
    },
    draw: function (redraw) {
        if (!this.is_moving && !redraw) return;
        this.renderer.clear_canvas();

        for (var i = 0; i < this.stars.length; i++) {
            var star = this.stars[i];

            if (this.direction == 0) {
                // don't rotate
            } else if (this.direction == 1) star.rotate_x();
            else if (this.direction == 2) star.rotate_y();
            else if (this.direction == 3) star.rotate_z();

            star.project_star(); // calculate renderering coordinates
            this.draw_star(i, this.star_radius, star.projected_z + ',' + star.projected_z + ',' + star.projected_z);
        }

        // draw the selected star (if any)
        if (this.selected != -1) {
            this.draw_star(this.selected, this.star_radius + 1, '255,0,0');
        }

        if (this.show_wormholes) {
            var stars = this.stars;
            for (var i = 0; i < this.wormholes.length; i++) {
                var wormhole = this.wormholes[i];
                this.draw_wormhole(stars[wormhole.from], stars[wormhole.to], wormhole.color);
            }
        }
        if (this.is_moving) {
            // http://stackoverflow.com/questions/1101668/how-to-use-settimeout-to-invoke-object-itself
            // Also, need to clear the last timeout first. Probably a better
            // way of doing this.
            var _this = this;
            if (this.last_timout) clearTimeout(this.last_timout);
            this.last_timout = setTimeout(function () {
                _this.draw()
            }, _this.loop_timeout);
        }
    },
    last_timout: null,
    toggle_wormholes: function () {
        if (this.show_wormholes) this.show_wormholes = false;
        else this.show_wormholes = true;
        this.draw(true);
    },
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
    toggle_rotation: function () {
        if (this.is_moving) {
            this.is_moving = false;
            this.degree = 0;
        } else {
            this.rotate_stars(2);
        }
        this.draw();
    },
    toggle_names: function () {
        if (this.show_names) {
            this.show_names = false;
        } else {
            this.show_names = true;
        }
        this.draw(true);
    },
    toggle_unreachable: function () {
        if (this.show_unreachable) {
            this.show_unreachable = false;
        } else {
            this.show_unreachable = true;
        }
        this.draw(true);
    },
    draw_star: function (index, radius, rgb) {
        var star = this.stars[index];
        if (!this.show_unreachable && !star.reachable) {
            return;
        }
        this.renderer.draw_circle(star.projected_x, star.projected_y, radius, rgb);
        if (this.show_names) {
            size = parseInt(10 * (7 + (7 * star.projected_z) / 255)) / 10;
            this.renderer.draw_text(star.name, star.projected_x - 20, star.projected_y - 5, size);
        }
    },
    draw_wormhole: function (from, to, color) {
        if (!this.show_unreachable && !from.reachable) {
            return;
        }
        this.renderer.draw_line(from.projected_x, from.projected_y, to.projected_x, to.projected_y, color);
    },
    rotate_stars: function (direction) {
        this.degree = this.rotate_angle;
        this.direction = direction;
        if (!this.is_moving) {
            this.is_moving = true;
            this.draw();
        }
    },
    load_stars: function () {

        this.stars[0] = new star(0, 0, 0, "Sol  ", "G2", "8", "6", 1);
        this.stars[1] = new star(-23.1, -19.18, -53.76, "Alpha Centauri A", "G2", "6", "9", 1);
        this.stars[2] = new star(-23.1, -19.18, -53.76, "Alpha Centauri B", "K0", "0", "0", 0);
        this.stars[3] = new star(-21.56, -16.38, -52.5, "Proxima Centauri C", "M5.5", "0", "0", 0);
        this.stars[4] = new star(-0.98, -82.88, 6.86, "Barnard's Star  ", "M5", "3", "1", 1);
        this.stars[5] = new star(-104.16, 29.82, 13.3, "Wolf 359  ", "M6", "4", "6", 1);
        this.stars[6] = new star(-91.28, 23.1, 68.32, "Lalande 21185  ", "M2", "1", "8", 1);
        this.stars[7] = new star(-22.54, 113.12, -34.58, "Sirius A", "A1", "4", "3", 1);
        this.stars[8] = new star(-22.54, 113.12, -34.58, "Sirius B", "DA2", "0", "0", 0);
        this.stars[9] = new star(105.56, 48.72, -37.66, "L 726-8 A", "M5.5", "5", "2", 1);
        this.stars[10] = new star(105.56, 48.72, -37.66, "L 726-8 B", "M5.5", "0", "0", 0);
        this.stars[11] = new star(26.46, -121.24, -54.88, "Ross 154  ", "M4.5", "4", "4", 1);
        this.stars[12] = new star(103.32, -8.54, 100.8, "Ross 248  ", "M6", "1", "2", 1);
        this.stars[13] = new star(87.22, 115.92, -24.22, "Epsilon Eridani  ", "K2", "4", "5", 1);
        this.stars[14] = new star(118.3, -28.84, -87.92, "Lacaille 9352  ", "M2", "2", "5", 1);
        this.stars[15] = new star(-152.18, 8.54, 2.1, "Ross 128  ", "M4.5", "3", "9", 1);
        this.stars[16] = new star(140.14, -52.36, -40.88, "L 789-6 A", "M5.5", "2", "4", 1);
        this.stars[17] = new star(140.14, -52.36, -40.88, "L 789-6 B", "M5", "0", "0", 0);
        this.stars[18] = new star(140.14, -52.36, -40.88, "L 789-6 C", "M7", "0", "0", 0);
        this.stars[19] = new star(-66.64, 144.48, 14.56, "Procyon A", "F5", "1", "7", 1);
        this.stars[20] = new star(-66.64, 144.48, 14.56, "Procyon B", "DA", "0", "0", 0);
        this.stars[21] = new star(90.44, -85.68, 99.96, "61 Cygni A", "K5", "2", "5", 0);
        this.stars[22] = new star(90.44, -85.68, 99.96, "61 Cygni B", "K7", "0", "0", 0);
        this.stars[23] = new star(14.98, -80.78, 140.14, "Struve 2398 A", "M4", "3", "3", 1);
        this.stars[24] = new star(14.98, -80.78, 140.14, "Struve 2398 B", "M5", "0", "0", 0);
        this.stars[25] = new star(116.76, 9.24, 113.26, "Groombridge 34 A", "M2", "3", "5", 0);
        this.stars[26] = new star(116.76, 9.24, 113.26, "Groombridge 34 B", "M6", "0", "0", 0);
        this.stars[27] = new star(-89.6, 117.6, 74.62, "G51-15  ", "M6.5", "3", "8", 1);
        this.stars[28] = new star(79.24, -44.24, -138.6, "Epsilon Indi A", "K4", "3", "1", 0);
        this.stars[29] = new star(79.38, -43.96, -138.6, "Epsilon Indi B", "T1", "0", "0", 0);
        this.stars[30] = new star(79.38, -43.96, -138.6, "Epsilon Indi C", "T6", "0", "0", 0);
        this.stars[31] = new star(143.92, 70.28, -45.78, "Tau Ceti  ", "G8", "3", "2", 1);
        this.stars[32] = new star(70.7, 97.44, -118.44, "L 372-58  ", "M5.5", "3", "1", 1);
        this.stars[33] = new star(154.28, 50.26, -49.56, "L 725-32  ", "M5", "1", "4", 1);
        this.stars[34] = new star(-64.12, 160.44, 15.82, "Luyten's Star  ", "M3.5", "2", "5", 1);
        this.stars[35] = new star(122.78, 115.5, 51.24, "SO 0253+1652  ", "M6.5", "3", "3", 1);
        this.stars[36] = new star(26.74, 123.62, -126.56, "Kapteyn's Star  ", "M1", "2", "2", 1);
        this.stars[37] = new star(15.4, -77.42, -161.56, "SCR 1845-6357 A", "M8.5", "3", "1", 0);
        this.stars[38] = new star(15.4, -77.42, -161.56, "SCR 1845-6357 B", "T5.5", "0", "0", 0);
        this.stars[39] = new star(106.26, -91.56, -113.12, "Lacaille 8760  ", "M0", "1", "4", 1);
        this.stars[40] = new star(90.02, -38.22, 154.7, "Kruger 60 A", "M3", "2", "9", 0);
        this.stars[41] = new star(90.02, -38.22, 154.7, "Kruger 60 B", "M6", "0", "0", 0);
        this.stars[42] = new star(-134.4, 43.68, -118.3, "DENIS 1048-39  ", "M9", "1", "13", 1);
        this.stars[43] = new star(-23.8, 186.34, -9.24, "Ross 614 A", "M4.5", "0", "9", 0);
        this.stars[44] = new star(-23.8, 186.34, -9.24, "Ross 614 B", "M7", "0", "0", 0);
        this.stars[45] = new star(-72.66, -175.56, -42.7, "Wolf 1061  ", "M3.5", "1", "5", 1);
        this.stars[46] = new star(-192.22, -27.86, 30.8, "Wolf 424 A", "M5.5", "3", "9", 1);
        this.stars[47] = new star(-192.22, -27.86, 30.8, "Wolf 424 B", "M7", "0", "0", 0);
        this.stars[48] = new star(158.2, 3.5, -120.82, "CD-37 15492  ", "M4", "1", "4", 1);
        this.stars[49] = new star(195.72, 42.56, 18.9, "van Maanen's Star  ", "DZ7", "1", "4", 1);
        this.stars[50] = new star(172.06, 99.4, 46.06, "L 1159-16  ", "M8", "1", "8", 1);
        this.stars[51] = new star(-93.1, 32.06, -179.06, "L 143-23  ", "M5.5", "2", "10", 1);
        this.stars[52] = new star(-192.64, 62.58, -40.6, "LP 731-58  ", "M6.5", "2", "14", 1);
        this.stars[53] = new star(-7.98, -75.88, 192.22, "BD+68 946  ", "M3.5", "2", "8", 1);
        this.stars[54] = new star(-19.6, -140.14, -151.34, "CD-46 11540  ", "M3", "1", "6", 0);
        this.stars[55] = new star(-89.6, 5.88, -190.96, "L 145-141  ", "DQ6", "2", "10", 1);
        this.stars[56] = new star(212.66, 5.74, -28.14, "G158-27  ", "M5.5", "2", "6", 1);
        this.stars[57] = new star(199.36, -59.92, -52.92, "Ross 780  ", "M5", "2", "6", 1);
        this.stars[58] = new star(72.94, -135.52, 150.78, "G208-44 A", "M5.5", "1", "7", 0);
        this.stars[59] = new star(72.94, -135.52, 150.78, "G208-44 B", "M6", "0", "0", 0);
        this.stars[60] = new star(72.94, -135.52, 150.78, "G208-44 C", "M8", "0", "0", 0);
        this.stars[61] = new star(-155.4, 37.94, 152.04, "Lalande 21258 A", "M2", "2", "9", 0);
        this.stars[62] = new star(-155.4, 37.94, 151.9, "Lalande 21258 B", "M6", "0", "0", 0);
        this.stars[63] = new star(-128.66, 66.22, 168.98, "Groombridge 1618  ", "K7", "2", "9", 1);
        this.stars[64] = new star(110.32, 105.56, -163.8, "DENIS 0255-47  ", "L8", "1", "3", 1);
        this.stars[65] = new star(-190.54, 89.74, 76.16, "BD+20 2465  ", "M4.5", "2", "10", 1);
        this.stars[66] = new star(118.44, -88.34, -170.1, "L 354-89  ", "M1", "1", "7", 0);
        this.stars[67] = new star(106.54, 150.92, -131.46, "LP 944-20  ", "M9", "1", "4", 1);
        this.stars[68] = new star(-16.52, -163.94, -160.86, "CD-44 11909  ", "M3.5", "2", "6", 0);
        this.stars[69] = new star(100.94, 204.68, -30.66, "Omicron² Eridani A", "K1", "1", "10", 0);
        this.stars[70] = new star(100.94, 204.68, -30.66, "Omicron² Eridani B", "DA4", "0", "0", 0);
        this.stars[71] = new star(100.94, 204.68, -30.66, "Omicron² Eridani C", "M4.5", "0", "0", 0);
        this.stars[72] = new star(156.38, -52.22, 161.14, "BD+43 4305  ", "M4.5", "1", "2", 0);
        this.stars[73] = new star(5.18, -231.98, 10.08, "70 Ophiuchi A", "K0", "2", "8", 1);
        this.stars[74] = new star(5.18, -231.98, 10.08, "70 Ophiuchi B", "K5", "0", "0", 0);
        this.stars[75] = new star(107.24, -205.66, 36.12, "Altair  ", "A7", "1", "9", 1);
        this.stars[76] = new star(-157.5, 160.16, 80.78, "G9-38 A", "M5.5", "1", "7", 1);
        this.stars[77] = new star(-157.5, 160.16, 80.78, "G9-38 B", "M5.5", "0", "0", 0);
        this.stars[78] = new star(232.12, 15.26, -67.34, "L 722-22 A", "M4", "1", "8", 1);
        this.stars[79] = new star(232.12, 15.26, -67.34, "L 722-22 B", "M6", "0", "0", 0);
        this.stars[80] = new star(0, 244.86, 11.48, "G99-49  ", "M4", "1", "3", 0);
        this.stars[81] = new star(-48.3, 2.66, 241.5, "G254-29  ", "M4", "1", "6", 0);
        this.stars[82] = new star(-214.9, -106.12, 63.7, "Lalande 25372  ", "M4", "1", "10", 1);
        this.stars[83] = new star(62.16, 240.1, -30.24, "LP 656-38  ", "M3.5", "1", "4", 0);
        this.stars[84] = new star(163.66, -175.28, -73.22, "LP 816-60  ", "M5", "1", "6", 0);
        this.stars[85] = new star(49.14, 120.12, 215.74, "Stein 2051 A", "M4", "1", "8", 0);
        this.stars[86] = new star(49.14, 120.12, 215.74, "Stein 2051 B", "DC5", "0", "0", 0);
        this.stars[87] = new star(-49.28, 204.68, 138.18, "Wolf 294  ", "M4", "1", "7", 0);
        this.stars[88] = new star(33.04, -214.48, 140.84, "2MASS 1835+32  ", "M8.5", "1", "11", 0);
        this.stars[89] = new star(32.62, 257.18, -16.66, "Wolf 1453  ", "M1.5", "1", "7", 0);
        this.stars[90] = new star(114.24, 231.7, -43.54, "2MASS 0415-09  ", "T8.5", "1", "10", 0);
        this.stars[91] = new star(35.84, -84.28, 246.96, "Sigma Draconis  ", "K0", "1", "11", 1);
        this.stars[92] = new star(-10.78, 244.44, -98.14, "L 668-21 A", "M1", "1", "8", 1);
        this.stars[93] = new star(-10.78, 244.44, -98.14, "L 668-21 B", "T6", "0", "0", 0);
        this.stars[94] = new star(20.16, 257.32, 57.12, "Ross 47  ", "M4", "1", "11", 0);
        this.stars[95] = new star(-8.68, -142.94, -223.3, "L 205-128  ", "M3.5", "0", "4", 0);
        this.stars[96] = new star(87.08, -252.56, 24.22, "Wolf 1055 A", "M3.5", "0", "5", 0);
        this.stars[97] = new star(88.06, -252.28, 24.08, "Wolf 1055 B", "M8", "0", "0", 0);
        this.stars[98] = new star(-136.22, 209.58, -98.7, "L 674-15  ", "M4", "1", "8", 0);
        this.stars[99] = new star(-179.76, -175.28, -98.42, "Lalande 27173 A", "K5", "1", "7", 0);
        this.stars[100] = new star(-179.76, -175.28, -98.42, "Lalande 27173 B", "M1", "0", "0", 0);
        this.stars[101] = new star(-179.76, -175.28, -98.42, "Lalande 27173 C", "M3", "0", "0", 0);
        this.stars[102] = new star(-179.9, -175.28, -98.28, "Lalande 27173 D", "T8", "0", "0", 0);
        this.stars[103] = new star(64.82, -177.8, -192.92, "L 347-14  ", "M4.5", "1", "9", 0);
        this.stars[104] = new star(-118.72, 242.9, 16.8, "Ross 882  ", "M4.5", "0", "9", 0);
        this.stars[105] = new star(-122.5, -162.54, -178.78, "CD-40 9712  ", "M3", "1", "10", 1);
        this.stars[106] = new star(141.54, 30.8, 230.16, "Eta Cassiopeiae A", "G0", "0", "7", 0);
        this.stars[107] = new star(141.54, 30.8, 230.16, "Eta Cassiopeiae B", "K7", "0", "0", 0);
        this.stars[108] = new star(272.02, -13.02, 11.48, "Lalande 46650  ", "M2", "0", "9", 0);
        this.stars[109] = new star(-47.6, -239.68, -122.36, "36 Ophiuchi A", "K1", "1", "7", 0);
        this.stars[110] = new star(-47.6, -239.68, -122.36, "36 Ophiuchi B", "K1", "0", "0", 0);
        this.stars[111] = new star(-46.48, -239.4, -121.8, "36 Ophiuchi C", "K5", "0", "0", 0);
        this.stars[112] = new star(120.82, -187.74, -162.82, "CD-36 13940 A", "K3", "0", "9", 0);
        this.stars[113] = new star(120.82, -187.74, -162.82, "CD-36 13940 B", "M3.5", "0", "0", 0);
        this.stars[114] = new star(130.48, 154.42, -189, "82 Eridani  ", "G5", "0", "6", 0);
        this.stars[115] = new star(59.78, -95.48, -255.08, "Delta Pavonis  ", "G5", "0", "8", 0);
        this.stars[116] = new star(-213.36, -169.82, -60.48, "Wolf 1481  ", "M3", "0", "9", 0);

        this.wormholes[0] = {
            from: 0,
            to: 1,
            color: "255,255,255"
        };
        if (!this.stars[0].reachable) {
            this.wormholes[0].color = '0,255,255';
        }
        this.wormholes[1] = {
            from: 0,
            to: 4,
            color: "255,255,255"
        };
        if (!this.stars[0].reachable) {
            this.wormholes[1].color = '0,255,255';
        }
        this.wormholes[2] = {
            from: 0,
            to: 7,
            color: "255,255,255"
        };
        if (!this.stars[0].reachable) {
            this.wormholes[2].color = '0,255,255';
        }
        this.wormholes[3] = {
            from: 0,
            to: 9,
            color: "255,255,255"
        };
        if (!this.stars[0].reachable) {
            this.wormholes[3].color = '0,255,255';
        }
        this.wormholes[4] = {
            from: 0,
            to: 11,
            color: "255,255,255"
        };
        if (!this.stars[0].reachable) {
            this.wormholes[4].color = '0,255,255';
        }
        this.wormholes[5] = {
            from: 0,
            to: 12,
            color: "255,255,255"
        };
        if (!this.stars[0].reachable) {
            this.wormholes[5].color = '0,255,255';
        }
        this.wormholes[6] = {
            from: 0,
            to: 16,
            color: "255,255,255"
        };
        if (!this.stars[0].reachable) {
            this.wormholes[6].color = '0,255,255';
        }
        this.wormholes[7] = {
            from: 0,
            to: 19,
            color: "255,255,255"
        };
        if (!this.stars[0].reachable) {
            this.wormholes[7].color = '0,255,255';
        }
        this.wormholes[8] = {
            from: 1,
            to: 13,
            color: "0,0,235"
        };
        if (!this.stars[1].reachable) {
            this.wormholes[8].color = '0,255,255';
        }
        this.wormholes[9] = {
            from: 4,
            to: 23,
            color: "0,0,235"
        };
        if (!this.stars[4].reachable) {
            this.wormholes[9].color = '0,255,255';
        }
        this.wormholes[10] = {
            from: 4,
            to: 73,
            color: "0,0,235"
        };
        if (!this.stars[4].reachable) {
            this.wormholes[10].color = '0,255,255';
        }
        this.wormholes[11] = {
            from: 5,
            to: 6,
            color: "0,0,235"
        };
        if (!this.stars[5].reachable) {
            this.wormholes[11].color = '0,255,255';
        }
        this.wormholes[12] = {
            from: 5,
            to: 7,
            color: "0,0,235"
        };
        if (!this.stars[5].reachable) {
            this.wormholes[12].color = '0,255,255';
        }
        this.wormholes[13] = {
            from: 5,
            to: 27,
            color: "0,0,235"
        };
        if (!this.stars[5].reachable) {
            this.wormholes[13].color = '0,255,255';
        }
        this.wormholes[14] = {
            from: 5,
            to: 65,
            color: "0,0,235"
        };
        if (!this.stars[5].reachable) {
            this.wormholes[14].color = '0,255,255';
        }
        this.wormholes[15] = {
            from: 7,
            to: 34,
            color: "0,0,235"
        };
        if (!this.stars[7].reachable) {
            this.wormholes[15].color = '0,255,255';
        }
        this.wormholes[16] = {
            from: 7,
            to: 36,
            color: "0,0,235"
        };
        if (!this.stars[7].reachable) {
            this.wormholes[16].color = '0,255,255';
        }
        this.wormholes[17] = {
            from: 9,
            to: 13,
            color: "0,0,235"
        };
        if (!this.stars[9].reachable) {
            this.wormholes[17].color = '0,255,255';
        }
        this.wormholes[18] = {
            from: 9,
            to: 14,
            color: "0,0,235"
        };
        if (!this.stars[9].reachable) {
            this.wormholes[18].color = '0,255,255';
        }
        this.wormholes[19] = {
            from: 9,
            to: 31,
            color: "0,0,235"
        };
        if (!this.stars[9].reachable) {
            this.wormholes[19].color = '0,255,255';
        }
        this.wormholes[20] = {
            from: 9,
            to: 33,
            color: "0,0,235"
        };
        if (!this.stars[9].reachable) {
            this.wormholes[20].color = '0,255,255';
        }
        this.wormholes[21] = {
            from: 11,
            to: 1,
            color: "0,0,235"
        };
        if (!this.stars[11].reachable) {
            this.wormholes[21].color = '0,255,255';
        }
        this.wormholes[22] = {
            from: 11,
            to: 39,
            color: "0,0,235"
        };
        if (!this.stars[11].reachable) {
            this.wormholes[22].color = '0,255,255';
        }
        this.wormholes[23] = {
            from: 11,
            to: 45,
            color: "0,0,235"
        };
        if (!this.stars[11].reachable) {
            this.wormholes[23].color = '0,255,255';
        }
        this.wormholes[24] = {
            from: 13,
            to: 35,
            color: "0,0,235"
        };
        if (!this.stars[13].reachable) {
            this.wormholes[24].color = '0,255,255';
        }
        this.wormholes[25] = {
            from: 14,
            to: 48,
            color: "0,0,235"
        };
        if (!this.stars[14].reachable) {
            this.wormholes[25].color = '0,255,255';
        }
        this.wormholes[26] = {
            from: 15,
            to: 1,
            color: "0,0,235"
        };
        if (!this.stars[15].reachable) {
            this.wormholes[26].color = '0,255,255';
        }
        this.wormholes[27] = {
            from: 15,
            to: 42,
            color: "0,0,235"
        };
        if (!this.stars[15].reachable) {
            this.wormholes[27].color = '0,255,255';
        }
        this.wormholes[28] = {
            from: 15,
            to: 46,
            color: "0,0,235"
        };
        if (!this.stars[15].reachable) {
            this.wormholes[28].color = '0,255,255';
        }
        this.wormholes[29] = {
            from: 16,
            to: 57,
            color: "0,0,235"
        };
        if (!this.stars[16].reachable) {
            this.wormholes[29].color = '0,255,255';
        }
        this.wormholes[30] = {
            from: 21,
            to: 25,
            color: "0,0,235"
        };
        if (!this.stars[21].reachable) {
            this.wormholes[30].color = '0,255,255';
        }
        this.wormholes[31] = {
            from: 21,
            to: 58,
            color: "0,0,235"
        };
        if (!this.stars[21].reachable) {
            this.wormholes[31].color = '0,255,255';
        }
        this.wormholes[32] = {
            from: 23,
            to: 53,
            color: "0,0,235"
        };
        if (!this.stars[23].reachable) {
            this.wormholes[32].color = '0,255,255';
        }
        this.wormholes[33] = {
            from: 23,
            to: 91,
            color: "0,0,235"
        };
        if (!this.stars[23].reachable) {
            this.wormholes[33].color = '0,255,255';
        }
        this.wormholes[34] = {
            from: 25,
            to: 40,
            color: "0,0,235"
        };
        if (!this.stars[25].reachable) {
            this.wormholes[34].color = '0,255,255';
        }
        this.wormholes[35] = {
            from: 25,
            to: 72,
            color: "0,0,235"
        };
        if (!this.stars[25].reachable) {
            this.wormholes[35].color = '0,255,255';
        }
        this.wormholes[36] = {
            from: 27,
            to: 34,
            color: "0,0,235"
        };
        if (!this.stars[27].reachable) {
            this.wormholes[36].color = '0,255,255';
        }
        this.wormholes[37] = {
            from: 27,
            to: 65,
            color: "0,0,235"
        };
        if (!this.stars[27].reachable) {
            this.wormholes[37].color = '0,255,255';
        }
        this.wormholes[38] = {
            from: 28,
            to: 37,
            color: "0,0,235"
        };
        if (!this.stars[28].reachable) {
            this.wormholes[38].color = '0,255,255';
        }
        this.wormholes[39] = {
            from: 28,
            to: 54,
            color: "0,0,235"
        };
        if (!this.stars[28].reachable) {
            this.wormholes[39].color = '0,255,255';
        }
        this.wormholes[40] = {
            from: 28,
            to: 66,
            color: "0,0,235"
        };
        if (!this.stars[28].reachable) {
            this.wormholes[40].color = '0,255,255';
        }
        this.wormholes[41] = {
            from: 31,
            to: 13,
            color: "0,0,235"
        };
        if (!this.stars[31].reachable) {
            this.wormholes[41].color = '0,255,255';
        }
        this.wormholes[42] = {
            from: 31,
            to: 56,
            color: "0,0,235"
        };
        if (!this.stars[31].reachable) {
            this.wormholes[42].color = '0,255,255';
        }
        this.wormholes[43] = {
            from: 32,
            to: 36,
            color: "0,0,235"
        };
        if (!this.stars[32].reachable) {
            this.wormholes[43].color = '0,255,255';
        }
        this.wormholes[44] = {
            from: 32,
            to: 64,
            color: "0,0,235"
        };
        if (!this.stars[32].reachable) {
            this.wormholes[44].color = '0,255,255';
        }
        this.wormholes[45] = {
            from: 32,
            to: 67,
            color: "0,0,235"
        };
        if (!this.stars[32].reachable) {
            this.wormholes[45].color = '0,255,255';
        }
        this.wormholes[46] = {
            from: 35,
            to: 92,
            color: "0,0,235"
        };
        if (!this.stars[35].reachable) {
            this.wormholes[46].color = '0,255,255';
        }
        this.wormholes[47] = {
            from: 37,
            to: 68,
            color: "0,0,235"
        };
        if (!this.stars[37].reachable) {
            this.wormholes[47].color = '0,255,255';
        }
        this.wormholes[48] = {
            from: 37,
            to: 103,
            color: "0,0,235"
        };
        if (!this.stars[37].reachable) {
            this.wormholes[48].color = '0,255,255';
        }
        this.wormholes[49] = {
            from: 40,
            to: 81,
            color: "0,0,235"
        };
        if (!this.stars[40].reachable) {
            this.wormholes[49].color = '0,255,255';
        }
        this.wormholes[50] = {
            from: 46,
            to: 52,
            color: "0,0,235"
        };
        if (!this.stars[46].reachable) {
            this.wormholes[50].color = '0,255,255';
        }
        this.wormholes[51] = {
            from: 46,
            to: 82,
            color: "0,0,235"
        };
        if (!this.stars[46].reachable) {
            this.wormholes[51].color = '0,255,255';
        }
        this.wormholes[52] = {
            from: 49,
            to: 56,
            color: "0,0,235"
        };
        if (!this.stars[49].reachable) {
            this.wormholes[52].color = '0,255,255';
        }
        this.wormholes[53] = {
            from: 50,
            to: 35,
            color: "0,0,235"
        };
        if (!this.stars[50].reachable) {
            this.wormholes[53].color = '0,255,255';
        }
        this.wormholes[54] = {
            from: 51,
            to: 1,
            color: "0,0,235"
        };
        if (!this.stars[51].reachable) {
            this.wormholes[54].color = '0,255,255';
        }
        this.wormholes[55] = {
            from: 51,
            to: 55,
            color: "0,0,235"
        };
        if (!this.stars[51].reachable) {
            this.wormholes[55].color = '0,255,255';
        }
        this.wormholes[56] = {
            from: 52,
            to: 76,
            color: "0,0,235"
        };
        if (!this.stars[52].reachable) {
            this.wormholes[56].color = '0,255,255';
        }
        this.wormholes[57] = {
            from: 53,
            to: 63,
            color: "0,0,235"
        };
        if (!this.stars[53].reachable) {
            this.wormholes[57].color = '0,255,255';
        }
        this.wormholes[58] = {
            from: 55,
            to: 105,
            color: "0,0,235"
        };
        if (!this.stars[55].reachable) {
            this.wormholes[58].color = '0,255,255';
        }
        this.wormholes[59] = {
            from: 57,
            to: 78,
            color: "0,0,235"
        };
        if (!this.stars[57].reachable) {
            this.wormholes[59].color = '0,255,255';
        }
        this.wormholes[60] = {
            from: 61,
            to: 85,
            color: "0,0,235"
        };
        if (!this.stars[61].reachable) {
            this.wormholes[60].color = '0,255,255';
        }
        this.wormholes[61] = {
            from: 61,
            to: 87,
            color: "0,0,235"
        };
        if (!this.stars[61].reachable) {
            this.wormholes[61].color = '0,255,255';
        }
        this.wormholes[62] = {
            from: 63,
            to: 1,
            color: "0,0,235"
        };
        if (!this.stars[63].reachable) {
            this.wormholes[62].color = '0,255,255';
        }
        this.wormholes[63] = {
            from: 68,
            to: 109,
            color: "0,0,235"
        };
        if (!this.stars[68].reachable) {
            this.wormholes[63].color = '0,255,255';
        }
        this.wormholes[64] = {
            from: 69,
            to: 90,
            color: "0,0,235"
        };
        if (!this.stars[69].reachable) {
            this.wormholes[64].color = '0,255,255';
        }
        this.wormholes[65] = {
            from: 73,
            to: 75,
            color: "0,0,235"
        };
        if (!this.stars[73].reachable) {
            this.wormholes[65].color = '0,255,255';
        }
        this.wormholes[66] = {
            from: 80,
            to: 89,
            color: "0,0,235"
        };
        if (!this.stars[80].reachable) {
            this.wormholes[66].color = '0,255,255';
        }
        this.wormholes[67] = {
            from: 83,
            to: 94,
            color: "0,0,235"
        };
        if (!this.stars[83].reachable) {
            this.wormholes[67].color = '0,255,255';
        }
        this.wormholes[68] = {
            from: 84,
            to: 88,
            color: "0,0,235"
        };
        if (!this.stars[84].reachable) {
            this.wormholes[68].color = '0,255,255';
        }
        this.wormholes[69] = {
            from: 98,
            to: 99,
            color: "0,0,235"
        };
        if (!this.stars[98].reachable) {
            this.wormholes[69].color = '0,255,255';
        }
        this.draw();
    },
    select_star: function (event) {
        var renderer = this.renderer;
        var x = Event.pointerX(event) - renderer.canvas_offset_left;
        var y = Event.pointerY(event) - renderer.canvas_offset_top;
        var dist = this.star_radius + 4; // click distance from star center
        this.selected = -1;
        $('star_id').update('No star selected');
        for (var i = 0; i < this.stars.length; i++) {
            star = this.stars[i];
            if (star.projected_x > x - dist && star.projected_x < x + dist && star.projected_y > y - dist && star.projected_y < y + dist) {
                this.selected = i;
                if (star.wormholes == 0) {
                    $('star_id').update("Name: " + star.name + '<br />Type: ' + star.type);
                } else {
                    $('star_id').update(
                        "Name: " + star.name + '<br />Type: ' + star.type + '<br />Wormholes: ' + star.wormholes + '<br />Stations: ' + star.stations);
                }
                break;
            }
        }
        this.draw();
    }
};

Event.observe(window, "load", function () {
    map.initialize('starmap');
    add_event_handlers();
    $('toggle_wormholes').checked = true;
    $('toggle_rotation').checked = true;
    $('toggle_names').checked = true;
    $('toggle_unreachable').checked = true;
});

function add_event_handlers() {
    Event.observe($('toggle_wormholes'), 'click', function () {
        map.toggle_wormholes();
    });
    Event.observe($('toggle_rotation'), 'click', function () {
        map.toggle_rotation();
    });
    Event.observe($('toggle_names'), 'click', function () {
        map.toggle_names();
    });
    Event.observe($('toggle_unreachable'), 'click', function () {
        map.toggle_unreachable();
    });
    Event.observe($('starmap'), 'click', function (event) {
        map.select_star(event);
    });
    Event.observe($('starmap'), 'mouseover', function(event) {
        map.stop_rotation();
        $('toggle_rotation').checked = false;
    });
    Event.observe($('starmap'), 'mouseout', function(event) {
        map.restart_rotation();
        $('toggle_rotation').checked = map.is_moving;
    });
}
