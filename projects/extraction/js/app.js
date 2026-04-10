import { DOMAIN_LABELS, DOMAIN_KEYS, NUMERIC_MAP, COUNTRY_NAMES, computeComposite, normalizeWeights } from './lib.js';

const SOURCE_URLS = {
  wb_gini: 'https://data.worldbank.org/indicator/SI.POV.GINI',
  ilo_labor_share: 'https://ilostat.ilo.org/data/',
  wb_net_interest_margin: 'https://data.worldbank.org/indicator/GFDD.EI.01',
  wb_domestic_credit: 'https://data.worldbank.org/indicator/FS.AST.PRVT.GD.ZS',
  wb_natural_rents: 'https://data.worldbank.org/indicator/NY.GDP.TOTL.RT.ZS',
  wb_wgi_corruption: 'https://data.worldbank.org/indicator/CC.EST',
  wb_reg_quality: 'https://data.worldbank.org/indicator/RQ.EST',
  wb_wgi_gov_eff: 'https://data.worldbank.org/indicator/GE.EST',
  rsf_press: 'https://rsf.org/en/index',
  tjn_fsi: 'https://fsi.taxjustice.net/',
  vdem_political_corruption: 'https://www.v-dem.net/',
  vdem_clientelism: 'https://www.v-dem.net/',
  vdem_electoral_democracy: 'https://www.v-dem.net/',
  vdem_physical_violence: 'https://www.v-dem.net/',
  vdem_freedom_of_expression: 'https://www.v-dem.net/',
  vdem_alternative_info_sources: 'https://www.v-dem.net/',
  vdem_rule_of_law: 'https://www.v-dem.net/',
  vdem_egalitarian: 'https://www.v-dem.net/',
  vdem_participatory_democracy: 'https://www.v-dem.net/',
};

const CONFIDENCE_OPACITY = { high: 1.0, moderate: 0.75, low: 0.5, very_low: 0.3 };
const TREND_ARROWS = { rising: '↑', falling: '↓', stable: '→', unknown: '?' };
const TREND_TIPS = {
  rising: 'Extraction is increasing over the past decade',
  falling: 'Extraction is decreasing over the past decade',
  stable: 'Extraction has been roughly stable over the past decade',
  unknown: 'Not enough data to determine trend',
};

// Color scale: Crameri "lajolla" — perceptually uniform, colorblind-safe
// See: Crameri et al. (2020) "The misuse of colour in science communication"
// https://www.nature.com/articles/s41467-020-19160-7
// Domain is recalibrated from actual data in init() via updateColorScale()
const LAJOLLA_COLORS = [
  '#FFFFCC',
  '#FBE69C',
  '#F6D869',
  '#EEB655',
  '#E89652',
  '#E1744F',
  '#CE534C',
  '#A04543',
  '#702E2E',
  '#402716',
  '#1A1A00',
];
let extractionColor = d3
  .scaleLinear()
  .domain(LAJOLLA_COLORS.map((_, i) => (i / (LAJOLLA_COLORS.length - 1)) * 100))
  .range(LAJOLLA_COLORS)
  .clamp(true);

function updateColorScale() {
  const countries = scoreData?.countries || {};
  const scores = Object.values(countries)
    .map((c) => c.composite_score ?? 0)
    .sort((a, b) => a - b);
  if (scores.length < 3) return;
  const lo = scores[0];
  const hi = scores[scores.length - 1];
  extractionColor = d3
    .scaleLinear()
    .domain(LAJOLLA_COLORS.map((_, i) => lo + (i / (LAJOLLA_COLORS.length - 1)) * (hi - lo)))
    .range(LAJOLLA_COLORS)
    .clamp(true);
}

let scoreData = null;
let currentWeights = {};
let selectedCountryCode = null;

// -- Load data --
async function init() {
  const [world, scores] = await Promise.all([
    d3.json('https://cdn.jsdelivr.net/npm/world-atlas@2/countries-110m.json'),
    d3.json('data/scores.json'),
  ]);

  scoreData = scores;

  // Initialize equal weights
  DOMAIN_KEYS.forEach((k) => {
    currentWeights[k] = scores.metadata.default_weights[k] || 1 / DOMAIN_KEYS.length;
  });

  updateColorScale();
  drawMap(world);
  drawLegendGradient();
  setupWeightControls();
  populateCountrySelect('alpha');
}

// -- ISO numeric → alpha-3 mapping --
const numericToAlpha3 = {};
Object.assign(numericToAlpha3, NUMERIC_MAP);

// TopoJSON geometries with no numeric id — map properties.name → alpha3
const NAME_TO_ALPHA3 = {
  Kosovo: 'XKX',
  Somaliland: 'SML',
  'N. Cyprus': 'NCY',
};

function getCountryAlpha3FromFeature(d) {
  if (d.id != null) return numericToAlpha3[String(d.id).padStart(3, '0')] || null;
  return NAME_TO_ALPHA3[d.properties?.name] || null;
}

function getCountryName(alpha3) {
  const cd = getCountryData(alpha3);
  return cd?.name || COUNTRY_NAMES[alpha3] || alpha3;
}

function getCountryData(alpha3) {
  return scoreData?.countries?.[alpha3] || null;
}

// -- Map --
let mapZoom = null;
let mapSvg = null;
let mapG = null;
let mapProjection = null;
let mapPath = null;
let mapWidth = 0;
let mapHeight = 0;

function drawMap(world) {
  mapSvg = d3.select('#map-svg');
  const container = document.querySelector('.map-container');
  mapWidth = container.clientWidth;
  mapHeight = container.clientHeight;
  mapSvg.attr('viewBox', `0 0 ${mapWidth} ${mapHeight}`);

  mapProjection = d3
    .geoNaturalEarth1()
    .fitSize([mapWidth - 20, mapHeight - 20], topojson.feature(world, world.objects.countries))
    .translate([mapWidth / 2, mapHeight / 2]);

  mapPath = d3.geoPath(mapProjection);
  const countries = topojson.feature(world, world.objects.countries).features;

  const tooltip = d3.select('#tooltip');

  // Create a group for all country paths (zoom transforms this group)
  mapG = mapSvg.append('g').attr('class', 'countries-group');

  mapG
    .selectAll('.country-path')
    .data(countries)
    .join('path')
    .attr('class', (d) => {
      const a3 = getCountryAlpha3FromFeature(d);
      const cd = getCountryData(a3);
      let cls = 'country-path';
      if (cd?.disputed) cls += ' disputed';
      return cls;
    })
    .attr('d', mapPath)
    .attr('fill', (d) => countryFill(d))
    .attr('opacity', (d) => countryOpacity(d))
    .on('mousemove', (event, d) => {
      const a3 = getCountryAlpha3FromFeature(d);
      const cd = getCountryData(a3);
      const name = getCountryName(a3) || d.properties?.name || `#${d.id}`;
      const score = cd ? computeComposite(cd.domains, currentWeights, DOMAIN_KEYS) : null;
      tooltip.html(
        `<strong>${name}</strong>` +
          (score !== null
            ? `<span class="tooltip-score">${score}</span>`
            : ' <span style="color:var(--text-muted)">No data</span>'),
      );
      tooltip
        .classed('visible', true)
        .style('left', event.offsetX + 14 + 'px')
        .style('top', event.offsetY - 10 + 'px');
    })
    .on('mouseleave', () => tooltip.classed('visible', false))
    .on('click', (event, d) => {
      const a3 = getCountryAlpha3FromFeature(d);
      selectCountry(a3, d.id);
    });

  // Zoom behavior
  mapZoom = d3
    .zoom()
    .scaleExtent([1, 8])
    .on('zoom', (event) => {
      mapG.attr('transform', event.transform);
    });

  mapSvg.call(mapZoom);

  // Zoom controls
  d3.select('#zoom-in').on('click', () => mapSvg.transition().duration(300).call(mapZoom.scaleBy, 1.5));
  d3.select('#zoom-out').on('click', () =>
    mapSvg
      .transition()
      .duration(300)
      .call(mapZoom.scaleBy, 1 / 1.5),
  );
  d3.select('#zoom-reset').on('click', () =>
    mapSvg.transition().duration(500).call(mapZoom.transform, d3.zoomIdentity),
  );
}

function countryFill(d) {
  const a3 = getCountryAlpha3FromFeature(d);
  const cd = getCountryData(a3);
  if (!cd) return getComputedStyle(document.documentElement).getPropertyValue('--no-data-fill').trim();
  const score = computeComposite(cd.domains, currentWeights, DOMAIN_KEYS);
  return extractionColor(score);
}

function countryOpacity(d) {
  const a3 = getCountryAlpha3FromFeature(d);
  const cd = getCountryData(a3);
  if (!cd) return 0.8;
  return 1.0;
}

function refreshMapColors() {
  d3.selectAll('.country-path')
    .transition()
    .duration(400)
    .attr('fill', (d) => countryFill(d))
    .attr('opacity', (d) => countryOpacity(d));
}

// -- Legend gradient --
function drawLegendGradient() {
  const canvas = document.getElementById('legend-gradient');
  const ctx = canvas.getContext('2d');
  const domain = extractionColor.domain();
  const lo = domain[0],
    hi = domain[domain.length - 1];
  for (let x = 0; x < 180; x++) {
    const score = lo + (x / 179) * (hi - lo);
    ctx.fillStyle = extractionColor(score);
    ctx.fillRect(x, 0, 1, 12);
  }
  // Labels always show the theoretical 0–100 scale
  const labels = document.querySelector('.legend-labels');
  if (labels) {
    labels.innerHTML = `<span>0 — Low</span><span>100 — Extreme</span>`;
  }
}

// -- Country selection --
function selectCountry(alpha3, numericId) {
  d3.selectAll('.country-path').classed('selected', false);
  if (numericId != null || alpha3) {
    const sel = d3
      .selectAll('.country-path')
      .filter((d) =>
        numericId != null ? String(d.id) === String(numericId) : getCountryAlpha3FromFeature(d) === alpha3,
      );
    sel.classed('selected', true).raise();

    // Center map on selected country
    if (mapZoom && mapSvg && sel.size() > 0) {
      const bounds = mapPath.bounds(sel.datum());
      const dx = bounds[1][0] - bounds[0][0];
      const dy = bounds[1][1] - bounds[0][1];
      const cx = (bounds[0][0] + bounds[1][0]) / 2;
      const cy = (bounds[0][1] + bounds[1][1]) / 2;
      const scale = Math.min(8, 0.7 / Math.max(dx / mapWidth, dy / mapHeight));
      const translate = [mapWidth / 2 - scale * cx, mapHeight / 2 - scale * cy];
      mapSvg
        .transition()
        .duration(750)
        .call(mapZoom.transform, d3.zoomIdentity.translate(translate[0], translate[1]).scale(scale));
    }
  }

  const cd = getCountryData(alpha3);
  const empty = document.getElementById('panel-empty');
  const content = document.getElementById('panel-content');

  if (!cd) {
    empty.style.display = 'flex';
    content.style.display = 'none';
    empty.querySelector('h3').textContent = alpha3 ? `No data for ${getCountryName(alpha3)}` : 'Select a country';
    return;
  }

  selectedCountryCode = alpha3;
  empty.style.display = 'none';
  content.style.display = 'block';

  // Sync dropdown button text
  const pickerBtn = document.getElementById('picker-button');
  if (pickerBtn && cd) pickerBtn.textContent = cd.name;

  const composite = computeComposite(cd.domains, currentWeights, DOMAIN_KEYS);
  document.getElementById('country-name').textContent = cd.name;
  const scoreEl = document.getElementById('composite-score');
  scoreEl.textContent = composite;
  scoreEl.style.color = extractionColor(composite);

  document.getElementById('overall-confidence').textContent = `Confidence: ${cd.overall_confidence.replace('_', ' ')}`;

  const trendEl = document.getElementById('overall-trend');
  trendEl.className = `trend-badge ${cd.overall_trend}`;
  trendEl.textContent = `${TREND_ARROWS[cd.overall_trend]} ${TREND_TIPS[cd.overall_trend]}`;

  const notesEl = document.getElementById('country-notes');
  notesEl.textContent = cd.notes || '';
  notesEl.style.display = cd.notes ? 'block' : 'none';

  // Data advisories
  const advisories = [];
  const sel = d3
    .selectAll('.country-path')
    .filter((d) =>
      numericId != null ? String(d.id) === String(numericId) : getCountryAlpha3FromFeature(d) === alpha3,
    );
  if (sel.size() === 0) {
    advisories.push('This territory is too small to display on the world map.');
  }
  const nDomains = Object.keys(cd.domains).length;
  if (nDomains <= 3) {
    advisories.push(`Score is based on ${nDomains} of 7 domains \u2014 may not reflect overall extraction.`);
  }
  const advisoryEl = document.getElementById('data-advisory');
  advisoryEl.innerHTML = advisories.join(' ');

  drawRadar(cd.domains);
  drawDomainList(cd.domains);
}

// -- Radar chart --
function drawRadar(domains) {
  const svg = d3.select('#radar-svg');
  svg.selectAll('*').remove();

  const cx = 230,
    cy = 165,
    maxR = 120;
  const n = DOMAIN_KEYS.length;
  const angleSlice = (2 * Math.PI) / n;

  // Concentric rings
  [25, 50, 75, 100].forEach((level) => {
    const r = (level / 100) * maxR;
    svg
      .append('circle')
      .attr('cx', cx)
      .attr('cy', cy)
      .attr('r', r)
      .attr('fill', 'none')
      .attr('stroke', 'var(--overlay-subtle)')
      .attr('stroke-width', 0.5);
    if (level < 100) {
      svg
        .append('text')
        .attr('x', cx + 3)
        .attr('y', cy - r + 2)
        .attr('fill', 'var(--overlay-medium)')
        .attr('font-size', '9px')
        .text(level);
    }
  });

  // Axis lines and labels
  DOMAIN_KEYS.forEach((k, i) => {
    const angle = i * angleSlice - Math.PI / 2;
    const x2 = cx + maxR * Math.cos(angle);
    const y2 = cy + maxR * Math.sin(angle);

    svg
      .append('line')
      .attr('x1', cx)
      .attr('y1', cy)
      .attr('x2', x2)
      .attr('y2', y2)
      .attr('stroke', 'var(--overlay-subtle)')
      .attr('stroke-width', 0.5);

    // Label
    const lx = cx + (maxR + 18) * Math.cos(angle);
    const ly = cy + (maxR + 18) * Math.sin(angle);
    const label = DOMAIN_LABELS[k].replace('& ', '&\n');
    const lines = label.split('\n');
    const textAnchor = Math.abs(Math.cos(angle)) < 0.1 ? 'middle' : Math.cos(angle) > 0 ? 'start' : 'end';

    const g = svg
      .append('text')
      .attr('x', lx)
      .attr('y', ly)
      .attr('text-anchor', textAnchor)
      .attr('dominant-baseline', 'middle')
      .attr('fill', 'var(--text-secondary)')
      .attr('font-size', '9.5px');

    lines.forEach((line, li) => {
      g.append('tspan')
        .attr('x', lx)
        .attr('dy', li === 0 ? 0 : '1.1em')
        .text(line);
    });
  });

  // Data polygon
  const points = DOMAIN_KEYS.map((k, i) => {
    const angle = i * angleSlice - Math.PI / 2;
    const r = ((domains[k]?.score || 0) / 100) * maxR;
    return [cx + r * Math.cos(angle), cy + r * Math.sin(angle)];
  });

  // Confidence band (lighter fill)
  svg
    .append('polygon')
    .attr('points', points.map((p) => p.join(',')).join(' '))
    .attr('fill', 'var(--radar-accent)')
    .attr('stroke', 'var(--radar-accent-stroke)')
    .attr('stroke-width', 1.5);

  // Data points
  DOMAIN_KEYS.forEach((k, i) => {
    const angle = i * angleSlice - Math.PI / 2;
    const r = ((domains[k]?.score || 0) / 100) * maxR;
    const conf = CONFIDENCE_OPACITY[domains[k]?.confidence] || 0.3;

    svg
      .append('circle')
      .attr('cx', cx + r * Math.cos(angle))
      .attr('cy', cy + r * Math.sin(angle))
      .attr('r', 4)
      .attr('fill', extractionColor(domains[k]?.score || 0))
      .attr('opacity', conf)
      .attr('stroke', 'var(--radar-dot-fill)')
      .attr('stroke-width', 0.5)
      .attr('stroke-opacity', 0.5);
  });
}

// -- Domain list --
function drawDomainList(domains) {
  const container = document.getElementById('domain-list');
  container.innerHTML = '';

  DOMAIN_KEYS.forEach((k) => {
    const d = domains[k];
    if (!d) return;

    const div = document.createElement('div');
    div.className = 'domain-item';

    const color = extractionColor(d.score);
    const trend = d.trend || 'unknown';
    const conf = d.confidence || 'low';

    div.innerHTML = `
      <div class="domain-item-header">
        <span class="domain-name">${DOMAIN_LABELS[k]}</span>
        <span class="trend-badge ${trend}" style="font-size:0.7rem">${TREND_ARROWS[trend]} ${TREND_TIPS[trend]}</span>
      </div>
      <div class="domain-score-row">
        <span class="domain-score-value" style="color:${color}">${d.score}</span>
        <div class="domain-bar-track">
          <div class="domain-bar-fill" style="width:${d.score}%; background:${color}; opacity:${CONFIDENCE_OPACITY[conf]}"></div>
        </div>
      </div>
      ${
        d.indicators?.length
          ? `<ul class="domain-justification">${d.indicators
              .map((ind) => {
                const factsHtml = (ind.facts || []).map((f) => `<span class="context-fact">${f}</span>`).join('');
                return `<li>${ind.question} ${ind.label}${factsHtml}</li>`;
              })
              .join('')}</ul>`
          : d.justification
            ? `<ul class="domain-justification">${d.justification
                .split(/(?<=\.)\s+/)
                .filter((s) => s.trim())
                .map((s) => `<li>${s.replace(/\.$/, '')}</li>`)
                .join('')}</ul>`
            : ''
      }
      ${d.justification_detail ? `<a class="raw-data-toggle" href="#">Show raw data &#9656;</a><div class="raw-data-detail" style="display:none"><div class="domain-justification">${d.justification_detail}</div>${d.sources?.length ? `<div class="domain-sources">Sources: ${d.sources.map((s) => (SOURCE_URLS[s] ? `<a href="${SOURCE_URLS[s]}" target="_blank" rel="noopener">${s}</a>` : s)).join(', ')}</div>` : ''}</div>` : ''}
      <div class="domain-meta">
        <span class="confidence-badge">Confidence: ${conf.replace('_', ' ')}</span>
      </div>
    `;
    container.appendChild(div);

    // Wire up raw data toggle
    const toggle = div.querySelector('.raw-data-toggle');
    if (toggle) {
      toggle.addEventListener('click', (e) => {
        e.preventDefault();
        const detail = div.querySelector('.raw-data-detail');
        const visible = detail.style.display !== 'none';
        detail.style.display = visible ? 'none' : 'block';
        toggle.innerHTML = visible ? 'Show raw data &#9656;' : 'Hide raw data &#9662;';
      });
    }
  });
}

// -- Weight controls --
function setupWeightControls() {
  const toggle = document.getElementById('weights-toggle');
  const controls = document.getElementById('weights-controls');
  const sliderContainer = document.getElementById('weight-sliders');

  toggle.addEventListener('click', (e) => {
    e.stopPropagation();
    controls.classList.toggle('open');
  });

  // Close dropdown when clicking outside
  document.addEventListener('click', (e) => {
    if (!controls.contains(e.target) && e.target !== toggle) {
      controls.classList.remove('open');
    }
  });

  DOMAIN_KEYS.forEach((k) => {
    const row = document.createElement('div');
    row.className = 'weight-row';
    row.innerHTML = `
      <label title="${DOMAIN_LABELS[k]}">${DOMAIN_LABELS[k]}</label>
      <input type="range" min="0" max="100" value="${Math.round(currentWeights[k] * 100)}" data-key="${k}">
      <span class="weight-value">${Math.round(currentWeights[k] * 100)}%</span>
    `;
    sliderContainer.appendChild(row);

    const slider = row.querySelector('input');
    slider.addEventListener('input', () => {
      const rawWeights = {};
      sliderContainer.querySelectorAll('input[type="range"]').forEach((s) => {
        rawWeights[s.dataset.key] = parseInt(s.value);
      });
      const normalized = normalizeWeights(rawWeights);
      DOMAIN_KEYS.forEach((dk) => {
        currentWeights[dk] = normalized[dk];
      });
      sliderContainer.querySelectorAll('.weight-row').forEach((r) => {
        const inp = r.querySelector('input');
        r.querySelector('.weight-value').textContent = Math.round(currentWeights[inp.dataset.key] * 100) + '%';
      });
      refreshMapColors();
      if (selectedCountryCode) {
        const cd = getCountryData(selectedCountryCode);
        if (cd) {
          const composite = computeComposite(cd.domains, currentWeights, DOMAIN_KEYS);
          const scoreEl = document.getElementById('composite-score');
          scoreEl.textContent = composite;
          scoreEl.style.color = extractionColor(composite);
        }
      }
    });
  });

  document.getElementById('reset-weights').addEventListener('click', () => {
    const eq = 1 / DOMAIN_KEYS.length;
    DOMAIN_KEYS.forEach((k) => (currentWeights[k] = eq));
    sliderContainer.querySelectorAll('input[type="range"]').forEach((s) => {
      s.value = Math.round(eq * 100);
    });
    sliderContainer.querySelectorAll('.weight-value').forEach((v) => {
      v.textContent = Math.round(eq * 100) + '%';
    });
    refreshMapColors();
    if (selectedCountryCode) {
      const cd = getCountryData(selectedCountryCode);
      if (cd) {
        const composite = computeComposite(cd.domains, currentWeights, DOMAIN_KEYS);
        document.getElementById('composite-score').textContent = composite;
        document.getElementById('composite-score').style.color = extractionColor(composite);
      }
    }
  });
}

// -- Resize handler --
window.addEventListener('resize', () => {
  // Simple: reload on resize for projection recalculation
  // A production version would debounce and redraw
});

// -- Theme toggle --
(function initTheme() {
  const root = document.documentElement;
  const btn = document.getElementById('theme-toggle');
  const stored = localStorage.getItem('theme');
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)');

  function apply(theme) {
    if (theme === 'light') {
      root.setAttribute('data-theme', 'light');
      btn.textContent = '☾';
      btn.setAttribute('aria-label', 'Switch to dark mode');
    } else {
      root.removeAttribute('data-theme');
      btn.textContent = '☀';
      btn.setAttribute('aria-label', 'Switch to light mode');
    }
    refreshMapColors();
  }

  // Initial theme: stored preference > OS preference > dark
  const initial = stored || (prefersDark.matches ? 'dark' : 'light');
  apply(initial);

  btn.addEventListener('click', () => {
    const current = root.getAttribute('data-theme') === 'light' ? 'light' : 'dark';
    const next = current === 'light' ? 'dark' : 'light';
    localStorage.setItem('theme', next);
    apply(next);
  });

  prefersDark.addEventListener('change', (e) => {
    if (!localStorage.getItem('theme')) {
      apply(e.matches ? 'dark' : 'light');
    }
  });
})();

// -- Methodology modal --
(function initModal() {
  const backdrop = document.getElementById('modal-backdrop');
  const openBtn = document.getElementById('methodology-btn');
  const closeBtn = document.getElementById('modal-close');

  openBtn.addEventListener('click', () => backdrop.classList.add('visible'));
  closeBtn.addEventListener('click', () => backdrop.classList.remove('visible'));
  backdrop.addEventListener('click', (e) => {
    if (e.target === backdrop) backdrop.classList.remove('visible');
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') backdrop.classList.remove('visible');
  });
})();

// -- Country picker --
let countrySortMode = 'alpha';

function populateCountrySelect(sortBy) {
  countrySortMode = sortBy || countrySortMode;
  const list = document.getElementById('picker-list');
  const toggle = document.getElementById('picker-sort-toggle');
  const countries = scoreData?.countries || {};
  const entries = Object.entries(countries).map(([code, data]) => ({
    code,
    name: data.name,
    composite: data.composite_score ?? 0,
  }));

  // Always compute rank from score order
  entries.sort((a, b) => b.composite - a.composite);
  const rankMap = new Map(entries.map((e, i) => [e.code, i + 1]));

  if (countrySortMode !== 'score') {
    entries.sort((a, b) => a.name.localeCompare(b.name));
  }

  const sortLabel = countrySortMode === 'score' ? 'Score' : 'Name';
  toggle.textContent = `\u21C5 Sort by: ${sortLabel}`;

  list.innerHTML = '';
  entries.forEach(({ code, name, composite }) => {
    const rank = rankMap.get(code);
    const div = document.createElement('div');
    div.className = 'picker-item' + (code === selectedCountryCode ? ' selected' : '');
    div.dataset.code = code;
    div.textContent = countrySortMode === 'score' ? `${rank}. ${name} (${composite})` : `${name} (#${rank})`;
    list.appendChild(div);
  });
}

(function initCountryPicker() {
  const picker = document.getElementById('country-picker');
  const button = document.getElementById('picker-button');
  const dropdown = document.getElementById('picker-dropdown');
  const toggle = document.getElementById('picker-sort-toggle');
  const list = document.getElementById('picker-list');

  button.addEventListener('click', () => {
    dropdown.classList.toggle('open');
  });

  // Close when clicking outside
  document.addEventListener('click', (e) => {
    if (!picker.contains(e.target)) {
      dropdown.classList.remove('open');
    }
  });

  // Sort toggle — stays open
  toggle.addEventListener('click', () => {
    countrySortMode = countrySortMode === 'alpha' ? 'score' : 'alpha';
    populateCountrySelect();
  });

  // Country selection — closes dropdown
  list.addEventListener('click', (e) => {
    const item = e.target.closest('.picker-item');
    if (!item) return;
    const code = item.dataset.code;
    const numId = Object.entries(numericToAlpha3).find(([, a3]) => a3 === code)?.[0];
    selectCountry(code, numId || null);
    button.textContent = item.textContent;
    dropdown.classList.remove('open');
  });
})();

// -- Draggable panel divider --
(() => {
  const divider = document.getElementById('panel-divider');
  const layout = document.querySelector('.layout');
  if (!divider || !layout) return;

  const MIN_PANEL = 300;
  const MAX_PANEL = 800;

  let dragging = false;

  divider.addEventListener('mousedown', (e) => {
    e.preventDefault();
    dragging = true;
    divider.classList.add('dragging');
    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';
  });

  document.addEventListener('mousemove', (e) => {
    if (!dragging) return;
    const layoutRect = layout.getBoundingClientRect();
    const panelWidth = Math.min(MAX_PANEL, Math.max(MIN_PANEL, layoutRect.right - e.clientX));
    layout.style.gridTemplateColumns = `1fr 6px ${panelWidth}px`;
  });

  document.addEventListener('mouseup', () => {
    if (!dragging) return;
    dragging = false;
    divider.classList.remove('dragging');
    document.body.style.cursor = '';
    document.body.style.userSelect = '';
  });
})();

init().catch((err) => {
  console.error('Failed to initialize:', err);
  document.querySelector('.no-data-note').textContent = 'Error loading data. See console.';
});
