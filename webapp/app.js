const STORAGE_KEY = "workout-log-v1";

const DEFAULT_EXERCISES = [
  "Back Squat",
  "Bench Press",
  "Deadlift",
  "Overhead Press",
  "Barbell Row",
  "Pull-Up",
  "Incline Dumbbell Press",
  "Romanian Deadlift",
  "Walking Lunge",
  "Lat Pulldown",
  "Cable Row",
  "Bicep Curl",
  "Tricep Pushdown",
  "Leg Press"
];

const state = loadState();
let deferredInstallPrompt = null;

const elements = {
  totalSessions: document.querySelector("#totalSessions"),
  last30Volume: document.querySelector("#last30Volume"),
  exerciseCount: document.querySelector("#exerciseCount"),
  workoutTitle: document.querySelector("#workoutTitle"),
  workoutDate: document.querySelector("#workoutDate"),
  workoutNotes: document.querySelector("#workoutNotes"),
  exerciseLibrary: document.querySelector("#exerciseLibrary"),
  customExerciseName: document.querySelector("#customExerciseName"),
  exerciseDraftList: document.querySelector("#exerciseDraftList"),
  historyList: document.querySelector("#historyList"),
  progressExercise: document.querySelector("#progressExercise"),
  personalBestValue: document.querySelector("#personalBestValue"),
  progressSessionCount: document.querySelector("#progressSessionCount"),
  bestWeightChart: document.querySelector("#bestWeightChart"),
  volumeChart: document.querySelector("#volumeChart"),
  installButton: document.querySelector("#installButton"),
  importData: document.querySelector("#importData")
};

init();

function init() {
  elements.workoutDate.value = formatDateInput(new Date());
  bindEvents();
  renderAll();
  registerServiceWorker();
}

function bindEvents() {
  document.querySelectorAll(".tab-button").forEach((button) => {
    button.addEventListener("click", () => switchTab(button.dataset.tab));
  });

  document.querySelector("#addLibraryExercise").addEventListener("click", () => {
    addDraftExercise(elements.exerciseLibrary.value || DEFAULT_EXERCISES[0]);
  });

  document.querySelector("#addBlankExercise").addEventListener("click", () => {
    addDraftExercise("");
  });

  document.querySelector("#addCustomExercise").addEventListener("click", () => {
    const name = elements.customExerciseName.value.trim();
    if (!name) {
      showToast("Enter a custom exercise name.");
      return;
    }
    registerCustomExercise(name);
    addDraftExercise(name);
    elements.customExerciseName.value = "";
    elements.exerciseLibrary.value = name;
    renderExerciseSelectors();
    renderProgress();
    showToast("Custom exercise added.");
  });

  document.querySelector("#saveWorkout").addEventListener("click", saveWorkout);
  document.querySelector("#exportData").addEventListener("click", exportData);
  elements.importData.addEventListener("change", importData);
  elements.progressExercise.addEventListener("change", renderProgress);

  window.addEventListener("beforeinstallprompt", (event) => {
    event.preventDefault();
    deferredInstallPrompt = event;
    elements.installButton.hidden = false;
  });

  elements.installButton.addEventListener("click", async () => {
    if (!deferredInstallPrompt) {
      return;
    }
    deferredInstallPrompt.prompt();
    await deferredInstallPrompt.userChoice;
    deferredInstallPrompt = null;
    elements.installButton.hidden = true;
  });
}

function renderAll() {
  renderOverview();
  renderExerciseSelectors();
  renderDrafts();
  renderHistory();
  renderProgress();
}

function renderOverview() {
  elements.totalSessions.textContent = state.sessions.length;
  elements.last30Volume.textContent = `${Math.round(totalVolumeLast30Days())} kg`;
  elements.exerciseCount.textContent = allExerciseNames().length;
}

function renderExerciseSelectors() {
  const names = allExerciseNames();
  elements.exerciseLibrary.innerHTML = names.map(optionHtml).join("");
  const progressNames = names.length ? names : DEFAULT_EXERCISES;
  elements.progressExercise.innerHTML = progressNames.map(optionHtml).join("");

  if (!progressNames.includes(state.selectedProgressExercise)) {
    state.selectedProgressExercise = progressNames[0] || "";
  }
  elements.progressExercise.value = state.selectedProgressExercise;
}

function renderDrafts() {
  elements.exerciseDraftList.innerHTML = "";

  if (!state.draftExercises.length) {
    addDraftExercise("");
    return;
  }

  const draftTemplate = document.querySelector("#exerciseDraftTemplate");
  const setTemplate = document.querySelector("#setRowTemplate");

  state.draftExercises.forEach((draft) => {
    const fragment = draftTemplate.content.cloneNode(true);
    const card = fragment.querySelector(".draft-card");
    const nameInput = fragment.querySelector(".exercise-name-input");
    const removeExerciseButton = fragment.querySelector(".remove-exercise-button");
    const setList = fragment.querySelector(".set-list");
    const addSetButton = fragment.querySelector(".add-set-button");

    nameInput.value = draft.name;
    nameInput.addEventListener("input", (event) => {
      draft.name = event.target.value;
    });

    removeExerciseButton.addEventListener("click", () => {
      if (state.draftExercises.length === 1) {
        showToast("Keep at least one exercise card open.");
        return;
      }
      state.draftExercises = state.draftExercises.filter((item) => item.id !== draft.id);
      renderDrafts();
    });

    draft.sets.forEach((set, index) => {
      const setFragment = setTemplate.content.cloneNode(true);
      setFragment.querySelector(".set-label").textContent = `Set ${index + 1}`;

      const weightInput = setFragment.querySelector(".set-weight-input");
      const repsInput = setFragment.querySelector(".set-reps-input");
      const removeSetButton = setFragment.querySelector(".remove-set-button");

      weightInput.value = set.weight || "";
      repsInput.value = set.reps || "";

      weightInput.addEventListener("input", (event) => {
        set.weight = Number(event.target.value);
      });

      repsInput.addEventListener("input", (event) => {
        set.reps = Number(event.target.value);
      });

      removeSetButton.addEventListener("click", () => {
        if (draft.sets.length === 1) {
          showToast("Each exercise needs at least one set row.");
          return;
        }
        draft.sets = draft.sets.filter((item) => item.id !== set.id);
        renderDrafts();
      });

      setList.appendChild(setFragment);
    });

    addSetButton.addEventListener("click", () => {
      draft.sets.push(createSet());
      renderDrafts();
    });

    elements.exerciseDraftList.appendChild(card);
  });
}

function renderHistory() {
  const sessions = [...state.sessions].sort((left, right) => right.date.localeCompare(left.date));
  if (!sessions.length) {
    elements.historyList.innerHTML = emptyState("No workouts yet", "Save your first session to build history.");
    return;
  }

  elements.historyList.innerHTML = sessions.map((session) => {
    const exerciseDetails = session.exercises.map((exercise) => `
      <div class="exercise-breakdown-item">
        <strong>${escapeHtml(exercise.name)}</strong>
        <div class="muted small">${exercise.sets.map((set) => `${formatNumber(set.weight)} kg x ${set.reps}`).join(" · ")}</div>
      </div>
    `).join("");

    return `
      <article class="history-card">
        <div class="history-header">
          <div>
            <h4>${escapeHtml(session.title)}</h4>
            <p class="muted small">${formatDisplayDate(session.date)}</p>
          </div>
        </div>
        <div class="pill-row">
          <span class="pill">${session.exercises.length} exercises</span>
          <span class="pill">${Math.round(totalSessionVolume(session))} kg volume</span>
        </div>
        <div class="exercise-breakdown">${exerciseDetails}</div>
      </article>
    `;
  }).join("");
}

function renderProgress() {
  const names = allExerciseNames();
  if (!names.length) {
    elements.personalBestValue.textContent = "0 kg";
    elements.progressSessionCount.textContent = "0";
    elements.bestWeightChart.innerHTML = emptyState("No data yet", "Log workouts to see your progress.");
    elements.volumeChart.innerHTML = emptyState("No data yet", "Log workouts to see your progress.");
    return;
  }

  state.selectedProgressExercise = elements.progressExercise.value || names[0];
  persistState();

  const points = progressPoints(state.selectedProgressExercise);
  const personalBest = points.reduce((best, point) => Math.max(best, point.bestWeight), 0);

  elements.personalBestValue.textContent = `${formatNumber(personalBest)} kg`;
  elements.progressSessionCount.textContent = String(points.length);
  elements.bestWeightChart.innerHTML = points.length
    ? buildLineChart(points, "bestWeight", "kg")
    : emptyState("No data for this exercise", "Log this lift to graph it.");
  elements.volumeChart.innerHTML = points.length
    ? buildBarChart(points, "totalVolume", "kg")
    : emptyState("No data for this exercise", "Log this lift to graph it.");
}

function saveWorkout() {
  const title = elements.workoutTitle.value.trim() || "Workout";
  const date = elements.workoutDate.value || formatDateInput(new Date());
  const notes = elements.workoutNotes.value.trim();

  const exercises = state.draftExercises
    .map((draft) => ({
      id: draft.id,
      name: draft.name.trim(),
      sets: draft.sets
        .map((set) => ({
          id: set.id,
          weight: Number(set.weight) || 0,
          reps: Number(set.reps) || 0
        }))
        .filter((set) => set.weight >= 0 && set.reps > 0)
    }))
    .filter((exercise) => exercise.name && exercise.sets.length);

  if (!exercises.length) {
    showToast("Add at least one valid exercise with reps before saving.");
    return;
  }

  exercises.forEach((exercise) => registerCustomExercise(exercise.name, false));

  state.sessions.push({
    id: crypto.randomUUID(),
    title,
    date,
    notes,
    exercises
  });

  state.draftExercises = [createDraftExercise("")];
  elements.workoutTitle.value = "";
  elements.workoutDate.value = formatDateInput(new Date());
  elements.workoutNotes.value = "";

  persistState();
  renderAll();
  showToast("Workout saved.");
}

function addDraftExercise(name) {
  state.draftExercises.push(createDraftExercise(name));
  renderDrafts();
}

function createDraftExercise(name) {
  return {
    id: crypto.randomUUID(),
    name,
    sets: [createSet()]
  };
}

function createSet() {
  return {
    id: crypto.randomUUID(),
    weight: 0,
    reps: 0
  };
}

function registerCustomExercise(name, persist = true) {
  const trimmed = name.trim();
  if (!trimmed) {
    return;
  }
  if (!state.customExercises.some((entry) => entry.toLowerCase() === trimmed.toLowerCase())) {
    state.customExercises.push(trimmed);
    state.customExercises.sort((left, right) => left.localeCompare(right));
    if (persist) {
      persistState();
    }
  }
}

function allExerciseNames() {
  const saved = state.sessions.flatMap((session) => session.exercises.map((exercise) => exercise.name));
  return [...new Set([...DEFAULT_EXERCISES, ...state.customExercises, ...saved])].sort((left, right) => left.localeCompare(right));
}

function progressPoints(exerciseName) {
  return [...state.sessions]
    .sort((left, right) => left.date.localeCompare(right.date))
    .flatMap((session) => {
      const exercise = session.exercises.find((item) => item.name === exerciseName);
      if (!exercise) {
        return [];
      }
      return [{
        date: session.date,
        bestWeight: exercise.sets.reduce((best, set) => Math.max(best, set.weight), 0),
        totalVolume: exercise.sets.reduce((total, set) => total + (set.weight * set.reps), 0)
      }];
    });
}

function totalSessionVolume(session) {
  return session.exercises.reduce(
    (total, exercise) => total + exercise.sets.reduce((exerciseTotal, set) => exerciseTotal + (set.weight * set.reps), 0),
    0
  );
}

function totalVolumeLast30Days() {
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 30);
  return state.sessions.reduce((total, session) => {
    return new Date(session.date) >= cutoff ? total + totalSessionVolume(session) : total;
  }, 0);
}

function switchTab(tabName) {
  document.querySelectorAll(".tab-button").forEach((button) => {
    button.classList.toggle("active", button.dataset.tab === tabName);
  });
  document.querySelectorAll(".tab-panel").forEach((panel) => {
    panel.classList.toggle("active", panel.id === `tab-${tabName}`);
  });
}

function buildLineChart(points, key, unit) {
  const width = 680;
  const height = 260;
  const padding = { top: 20, right: 24, bottom: 48, left: 46 };
  const values = points.map((point) => point[key]);
  const maxValue = Math.max(...values, 1);
  const chartWidth = width - padding.left - padding.right;
  const chartHeight = height - padding.top - padding.bottom;

  const coordinates = points.map((point, index) => {
    const x = padding.left + (points.length === 1 ? chartWidth / 2 : (chartWidth * index) / (points.length - 1));
    const y = padding.top + chartHeight - (point[key] / maxValue) * chartHeight;
    return { x, y, label: shortDate(point.date), value: point[key] };
  });

  const linePath = coordinates.map((point, index) => `${index === 0 ? "M" : "L"} ${point.x} ${point.y}`).join(" ");
  const fillPath = `${linePath} L ${coordinates.at(-1).x} ${height - padding.bottom} L ${coordinates[0].x} ${height - padding.bottom} Z`;

  const gridLines = [0, 0.25, 0.5, 0.75, 1].map((ratio) => {
    const y = padding.top + chartHeight - ratio * chartHeight;
    const value = Math.round(maxValue * ratio);
    return `
      <line class="chart-grid-line" x1="${padding.left}" y1="${y}" x2="${width - padding.right}" y2="${y}"></line>
      <text class="chart-axis-label" x="${padding.left - 10}" y="${y + 4}" text-anchor="end">${value} ${unit}</text>
    `;
  }).join("");

  const xLabels = coordinates.map((point) => `
    <text class="chart-axis-label" x="${point.x}" y="${height - 16}" text-anchor="middle">${point.label}</text>
  `).join("");

  const dots = coordinates.map((point) => `
    <circle class="point-dot" cx="${point.x}" cy="${point.y}" r="4"></circle>
  `).join("");

  return `
    <svg viewBox="0 0 ${width} ${height}" class="chart-svg" role="img" aria-label="Line chart of progress over time">
      ${gridLines}
      <line class="chart-axis" x1="${padding.left}" y1="${height - padding.bottom}" x2="${width - padding.right}" y2="${height - padding.bottom}"></line>
      <path class="line-fill" d="${fillPath}"></path>
      <path class="line-series" d="${linePath}"></path>
      ${dots}
      ${xLabels}
    </svg>
  `;
}

function buildBarChart(points, key, unit) {
  const width = 680;
  const height = 260;
  const padding = { top: 20, right: 24, bottom: 48, left: 46 };
  const maxValue = Math.max(...points.map((point) => point[key]), 1);
  const chartWidth = width - padding.left - padding.right;
  const chartHeight = height - padding.top - padding.bottom;
  const barWidth = Math.max(22, chartWidth / Math.max(points.length * 1.8, 1));

  const gridLines = [0, 0.25, 0.5, 0.75, 1].map((ratio) => {
    const y = padding.top + chartHeight - ratio * chartHeight;
    const value = Math.round(maxValue * ratio);
    return `
      <line class="chart-grid-line" x1="${padding.left}" y1="${y}" x2="${width - padding.right}" y2="${y}"></line>
      <text class="chart-axis-label" x="${padding.left - 10}" y="${y + 4}" text-anchor="end">${value} ${unit}</text>
    `;
  }).join("");

  const bars = points.map((point, index) => {
    const x = padding.left + ((index + 0.5) * chartWidth) / points.length - barWidth / 2;
    const barHeight = (point[key] / maxValue) * chartHeight;
    const y = padding.top + chartHeight - barHeight;
    const labelX = x + barWidth / 2;
    return `
      <rect class="bar-series" x="${x}" y="${y}" width="${barWidth}" height="${barHeight}" rx="8"></rect>
      <text class="chart-axis-label" x="${labelX}" y="${height - 16}" text-anchor="middle">${shortDate(point.date)}</text>
    `;
  }).join("");

  return `
    <svg viewBox="0 0 ${width} ${height}" class="chart-svg" role="img" aria-label="Bar chart of session volume over time">
      ${gridLines}
      <line class="chart-axis" x1="${padding.left}" y1="${height - padding.bottom}" x2="${width - padding.right}" y2="${height - padding.bottom}"></line>
      ${bars}
    </svg>
  `;
}

function exportData() {
  const blob = new Blob([JSON.stringify(state, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = `workout-log-backup-${formatDateInput(new Date())}.json`;
  anchor.click();
  URL.revokeObjectURL(url);
}

async function importData(event) {
  const [file] = event.target.files || [];
  if (!file) {
    return;
  }

  try {
    const text = await file.text();
    const parsed = JSON.parse(text);
    const imported = sanitizeState(parsed);
    state.sessions = imported.sessions;
    state.customExercises = imported.customExercises;
    state.draftExercises = imported.draftExercises.length ? imported.draftExercises : [createDraftExercise("")];
    state.selectedProgressExercise = imported.selectedProgressExercise;
    persistState();
    renderAll();
    showToast("Backup imported.");
  } catch (error) {
    console.error(error);
    showToast("Import failed. Use a valid backup JSON file.");
  } finally {
    event.target.value = "";
  }
}

function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) {
      return sanitizeState({});
    }
    return sanitizeState(JSON.parse(raw));
  } catch (error) {
    console.error(error);
    return sanitizeState({});
  }
}

function persistState() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

function sanitizeState(input) {
  return {
    sessions: Array.isArray(input.sessions) ? input.sessions : [],
    customExercises: Array.isArray(input.customExercises) ? input.customExercises : [],
    draftExercises: Array.isArray(input.draftExercises) && input.draftExercises.length
      ? input.draftExercises.map((draft) => ({
          id: draft.id || crypto.randomUUID(),
          name: draft.name || "",
          sets: Array.isArray(draft.sets) && draft.sets.length
            ? draft.sets.map((set) => ({
                id: set.id || crypto.randomUUID(),
                weight: Number(set.weight) || 0,
                reps: Number(set.reps) || 0
              }))
            : [createSet()]
        }))
      : [createDraftExercise("")],
    selectedProgressExercise: typeof input.selectedProgressExercise === "string" ? input.selectedProgressExercise : DEFAULT_EXERCISES[0]
  };
}

function emptyState(title, body) {
  return `<div class="empty-state"><div><strong>${escapeHtml(title)}</strong><p>${escapeHtml(body)}</p></div></div>`;
}

function optionHtml(name) {
  const safeName = escapeHtml(name);
  return `<option value="${safeName}">${safeName}</option>`;
}

function formatDisplayDate(date) {
  return new Date(date).toLocaleDateString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric"
  });
}

function shortDate(date) {
  return new Date(date).toLocaleDateString(undefined, {
    month: "short",
    day: "numeric"
  });
}

function formatDateInput(date) {
  return date.toISOString().slice(0, 10);
}

function formatNumber(value) {
  return Number.isInteger(value) ? String(value) : value.toFixed(1);
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function showToast(message) {
  const toast = document.createElement("div");
  toast.className = "toast";
  toast.textContent = message;
  document.body.appendChild(toast);
  setTimeout(() => toast.remove(), 2200);
}

function registerServiceWorker() {
  if ("serviceWorker" in navigator) {
    window.addEventListener("load", () => {
      navigator.serviceWorker.register("./service-worker.js").catch((error) => {
        console.error("Service worker registration failed", error);
      });
    });
  }
}
