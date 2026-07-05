/* ── 配置 ── */
const DEFAULT_IP   = '192.168.4.1';   // SS928 AP热点地址
const DEFAULT_PORT = 8080;
const POLL_MS      = 500;             // 实时数据轮询间隔

/* ── 状态 ── */
let serverIp   = localStorage.getItem('serverIp')   || DEFAULT_IP;
let serverPort = parseInt(localStorage.getItem('serverPort') || DEFAULT_PORT);
let connected  = false;
let currentMode = 'pullup';
let selectedGoal = 'free';
let allHistory   = [];
let currentFilter = 'all';
let pollTimer     = null;
let monthChartInst = null;
let showingChart   = false;

// 训练状态
let training    = false;
let paused      = false;
let trainStart  = 0;
let trainTimer  = null;
let lastCount   = 0;

/* ── 工具函数 ── */
function apiBase() { return `http://${serverIp}:${serverPort}`; }

function fmtDuration(secs) {
  if (!secs || secs <= 0) return '';
  const m = Math.floor(secs / 60), s = secs % 60;
  return m > 0 ? `${m}分${s > 0 ? s + '秒' : ''}` : `${s}秒`;
}

function fmtDurationShort(secs) {
  if (!secs || secs <= 0) return '0分';
  const m = Math.floor(secs / 60);
  return m > 0 ? `${m}分` : `${secs}秒`;
}

function scoreClass(score) {
  if (score >= 90) return 'score-green';
  if (score >= 75) return 'score-orange';
  return 'score-red';
}

function updateGreeting() {
  const h = new Date().getHours();
  const g = h < 6 ? '夜深了' : h < 12 ? '早上好' : h < 18 ? '下午好' : '晚上好';
  document.getElementById('greeting').textContent = g;
}

/* ── 页面切换 ── */
function switchPage(name, el) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  document.getElementById('page-' + name).classList.add('active');
  el.classList.add('active');
  if (name === 'data') { loadHistory(); }
  if (name === 'mine') { refreshMine(); }
}

/* ── 连接状态更新 ── */
function setConnected(val) {
  connected = val;
  const badge = document.getElementById('conn-badge');
  const text  = document.getElementById('conn-text');
  const statusText = document.getElementById('conn-status-text');
  if (val) {
    badge.className = 'conn-badge connected';
    text.textContent = '已连接';
    if (statusText) { statusText.textContent = '已连接'; statusText.style.color = 'var(--green)'; }
  } else {
    badge.className = 'conn-badge disconnected';
    text.textContent = '未连接';
    if (statusText) { statusText.textContent = '未连接'; statusText.style.color = 'var(--red)'; }
  }
  const goBtn  = document.getElementById('go-btn');
  const goHint = document.getElementById('go-hint');
  if (val) {
    goBtn.classList.remove('disabled');
    goHint.textContent = '将使用IMU传感器自动计数';
    goHint.classList.remove('error');
  } else {
    goBtn.classList.add('disabled');
    goHint.textContent = '请先连接设备';
    goHint.classList.add('error');
  }
}

/* ── 实时数据轮询 ── */
function startPolling() {
  if (pollTimer) return;
  pollTimer = setInterval(fetchLive, POLL_MS);
  fetchLive();
}

async function fetchLive() {
  try {
    const res  = await fetch(`${apiBase()}/api/imu/live`, { signal: AbortSignal.timeout(2000) });
    const data = await res.json();
    if (data.error) { setConnected(false); return; }
    setConnected(true);
    if (training && !paused) updateTrainingUI(data);
  } catch {
    setConnected(false);
  }
}

function updateTrainingUI(data) {
  document.getElementById('t-roll').textContent  = data.roll  !== undefined ? data.roll.toFixed(1)  + '°' : '--';
  document.getElementById('t-pitch').textContent = data.pitch !== undefined ? data.pitch.toFixed(1) + '°' : '--';
  document.getElementById('t-accz').textContent  = data.acc_z !== undefined ? data.acc_z : '--';
  const count = data.count || 0;
  if (count !== lastCount) {
    lastCount = count;
    document.getElementById('training-count').textContent = count;
    checkGoalReached(count);
  }
}

/* ── 模式切换 ── */
async function switchMode(mode) {
  currentMode = mode;
  document.getElementById('card-pullup').classList.toggle('selected', mode === 'pullup');
  document.getElementById('card-pushup').classList.toggle('selected', mode === 'pushup');
  try {
    await fetch(`${apiBase()}/api/mode`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ mode }),
      signal: AbortSignal.timeout(2000),
    });
  } catch {}
  updateLastRecords();
}

function updateLastRecords() {
  const pullupLast = allHistory.filter(r => r.action === '引体向上').slice(-1)[0];
  const pushupLast = allHistory.filter(r => r.action === '俯卧撑').slice(-1)[0];
  document.getElementById('last-pullup').textContent =
    pullupLast ? `上次：${pullupLast.count}个 · ${pullupLast.score.toFixed(0)}%标准` : '';
  document.getElementById('last-pushup').textContent =
    pushupLast ? `上次：${pushupLast.count}个 · ${pushupLast.score.toFixed(0)}%标准` : '';
}

/* ── 目标选择 ── */
function selectGoal(el) {
  document.querySelectorAll('.goal-chips .chip').forEach(c => c.classList.remove('selected'));
  el.classList.add('selected');
  selectedGoal = el.dataset.goal;
}

/* ── 训练开始/暂停/结束 ── */
function startTraining() {
  if (!connected) return;
  training  = true;
  paused    = false;
  lastCount = 0;
  trainStart = Date.now();
  document.getElementById('training-mode-label').textContent =
    currentMode === 'pullup' ? '引体向上' : '俯卧撑';
  document.getElementById('training-count').textContent = '0';
  document.getElementById('training-sub').textContent = goalLabel();
  document.getElementById('training-overlay').classList.remove('hidden');
  document.getElementById('btn-pause').textContent = '暂停';
  trainTimer = setInterval(tickTimer, 1000);
}

function goalLabel() {
  const map = { free:'自由训练', '10':'目标10个', '20':'目标20个', '30':'目标30个',
                '50':'目标50个', t1:'目标1分钟', t3:'目标3分钟', t5:'目标5分钟' };
  return map[selectedGoal] || '自由训练';
}

function checkGoalReached(count) {
  const numGoal = parseInt(selectedGoal);
  if (!isNaN(numGoal) && count >= numGoal) stopTraining();
}

function tickTimer() {
  if (paused) return;
  const elapsed = Math.floor((Date.now() - trainStart) / 1000);
  const m = Math.floor(elapsed / 60), s = elapsed % 60;
  document.getElementById('training-timer').textContent =
    `${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}`;
  // 时间目标检查
  if (selectedGoal === 't1' && elapsed >= 60)  stopTraining();
  if (selectedGoal === 't3' && elapsed >= 180) stopTraining();
  if (selectedGoal === 't5' && elapsed >= 300) stopTraining();
}

function togglePause() {
  paused = !paused;
  document.getElementById('btn-pause').textContent = paused ? '继续' : '暂停';
}

async function stopTraining() {
  clearInterval(trainTimer);
  training = false;
  paused   = false;
  document.getElementById('training-overlay').classList.add('hidden');
  const elapsed = Math.floor((Date.now() - trainStart) / 1000);
  // 自动保存
  try {
    const res  = await fetch(`${apiBase()}/api/imu/live`, { signal: AbortSignal.timeout(1000) });
    const data = await res.json();
    const count = data.count || lastCount || 0;
    if (count > 0) {
      const score = Math.min(count * 5.0 + 30, 100);
      const freq  = elapsed > 0 ? parseFloat((count / (elapsed / 60)).toFixed(1)) : 0;
      const record = {
        date:    new Date().toISOString().slice(0,10),
        action:  currentMode === 'pullup' ? '引体向上' : '俯卧撑',
        count,
        score:   parseFloat(score.toFixed(1)),
        duration_secs: elapsed,
        frequency: freq,
      };
      await fetch(`${apiBase()}/api/history`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(record),
        signal:  AbortSignal.timeout(2000),
      });
    }
  } catch {}
}

/* ── 历史数据 ── */
async function loadHistory() {
  try {
    const res  = await fetch(`${apiBase()}/api/history`, { signal: AbortSignal.timeout(5000) });
    const data = await res.json();
    allHistory = data.records || [];
  } catch {
    allHistory = [];
  }
  renderHistory();
  renderMonthStats();
  updateLastRecords();
  refreshMine();
}

function filterHistory(el) {
  document.querySelectorAll('.filter-bar .chip').forEach(c => c.classList.remove('selected'));
  el.classList.add('selected');
  currentFilter = el.dataset.filter;
  renderHistory();
}

function renderHistory() {
  const list = document.getElementById('history-list');
  const filtered = allHistory.filter(r => {
    if (currentFilter === 'all')    return true;
    if (currentFilter === 'pullup') return r.action === '引体向上';
    if (currentFilter === 'pushup') return r.action === '俯卧撑';
    return true;
  });

  if (filtered.length === 0) {
    list.innerHTML = '<div class="empty-tip">暂无训练记录</div>';
    return;
  }

  // 按日期分组，倒序
  const grouped = {};
  filtered.forEach(r => {
    if (!grouped[r.date]) grouped[r.date] = [];
    grouped[r.date].push(r);
  });
  const dates = Object.keys(grouped).sort((a, b) => b.localeCompare(a));

  list.innerHTML = dates.map(date => {
    const records = grouped[date];
    const cards = records.map(r => {
      const icon  = r.action === '引体向上' ? '💪' : '🏋️';
      const bg    = r.action === '引体向上' ? 'rgba(109,192,48,.12)' : 'rgba(100,150,255,.12)';
      const sc    = scoreClass(r.score);
      const detail = [
        `${r.count}个`,
        r.duration_secs > 0 ? fmtDuration(r.duration_secs) : '',
        r.frequency > 0 ? `${r.frequency.toFixed(1)}个/分` : '',
      ].filter(Boolean).join(' · ');
      return `
        <div class="record-card">
          <div class="record-icon-box" style="background:${bg}">${icon}</div>
          <div class="record-info">
            <div class="record-action">${r.action}</div>
            <div class="record-detail">${detail}</div>
          </div>
          <div class="score-badge ${sc}">${r.score.toFixed(0)}%</div>
        </div>`;
    }).join('');
    return `<div class="date-group-label">${date}</div>${cards}`;
  }).join('');
}

function renderMonthStats() {
  const now = new Date();
  const key = `${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,'0')}`;
  const month = allHistory.filter(r => r.date && r.date.startsWith(key));
  const count = month.length;
  const secs  = month.reduce((s, r) => s + (r.duration_secs || 0), 0);
  const score = count > 0 ? month.reduce((s, r) => s + r.score, 0) / count : 0;
  document.getElementById('stat-count').textContent = `${count}次`;
  document.getElementById('stat-time').textContent  = fmtDurationShort(secs);
  document.getElementById('stat-score').textContent = `${score.toFixed(0)}%`;

  // ECharts 折线（最近7条）
  const recent = [...allHistory].slice(-7);
  if (monthChartInst && recent.length > 0) {
    monthChartInst.setOption({
      grid: { top: 8, bottom: 20, left: 20, right: 20 },
      xAxis: { type: 'category', data: recent.map(r => r.date.slice(5)),
               axisLabel: { color: 'rgba(255,255,255,.6)', fontSize: 10 },
               axisLine: { show: false }, axisTick: { show: false } },
      yAxis: { type: 'value', show: false },
      series: [{ type: 'line', data: recent.map(r => r.count),
                 smooth: true, symbol: 'circle', symbolSize: 6,
                 lineStyle: { color: '#fff', width: 2 },
                 itemStyle: { color: '#fff' },
                 areaStyle: { color: 'rgba(255,255,255,.15)' } }],
    });
  }
}

function toggleMonthView() {
  showingChart = !showingChart;
  document.getElementById('month-stats').classList.toggle('hidden', showingChart);
  document.getElementById('month-chart').classList.toggle('hidden', !showingChart);
  document.getElementById('toggle-view-btn').textContent = showingChart ? '数字' : '曲线';
  if (showingChart && !monthChartInst) {
    monthChartInst = echarts.init(document.getElementById('month-chart'));
    renderMonthStats();
  }
  if (showingChart && monthChartInst) monthChartInst.resize();
}

/* ── 我的页 ── */
function refreshMine() {
  const total    = allHistory.length;
  const totalRep = allHistory.reduce((s, r) => s + (r.count || 0), 0);
  const totalSec = allHistory.reduce((s, r) => s + (r.duration_secs || 0), 0);
  document.getElementById('mine-total-tip').textContent  = `累计训练 ${total} 次`;
  document.getElementById('total-sessions').textContent  = `${total}次`;
  document.getElementById('total-reps').textContent      = `${totalRep}个`;
  document.getElementById('total-time').textContent      = fmtDurationShort(totalSec);
  document.getElementById('server-display').textContent  = `${serverIp}:${serverPort}`;
}

/* ── 服务器设置弹窗 ── */
function showServerDialog() {
  document.getElementById('input-ip').value   = serverIp;
  document.getElementById('input-port').value = serverPort;
  document.getElementById('server-modal').classList.remove('hidden');
  document.getElementById('modal-mask').classList.remove('hidden');
}

function closeModal() {
  document.getElementById('server-modal').classList.add('hidden');
  document.getElementById('modal-mask').classList.add('hidden');
}

function saveServer() {
  const ip   = document.getElementById('input-ip').value.trim();
  const port = parseInt(document.getElementById('input-port').value) || DEFAULT_PORT;
  if (ip) {
    serverIp   = ip;
    serverPort = port;
    localStorage.setItem('serverIp',   serverIp);
    localStorage.setItem('serverPort', serverPort);
    document.getElementById('server-display').textContent = `${serverIp}:${serverPort}`;
  }
  closeModal();
}

/* ── 初始化 ── */
updateGreeting();
setConnected(false);
startPolling();
loadHistory();
