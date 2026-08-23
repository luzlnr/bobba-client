(() => {
  const FRAME_DEFAULT = { FRAME_W: 430, FRAME_H: 268 };

  function uid(prefix) {
    return prefix + "_" + Math.random().toString(36).slice(2, 7);
  }

  function defaultItems() {
    return [
      { id: "canvas", kind: "canvas", label: "Lista de ícones", x: 6, y: 0, w: 300, h: 230, rotation: 0, scaleX: 1, scaleY: 1 },
      { id: "avatar", kind: "avatar", label: "Avatar", x: 314, y: 8, w: 100, h: 160, rotation: 0, scaleX: 1, scaleY: 1, fill: "#292929", stroke: "#222222" },
      { id: "name", kind: "text", label: "Nome", x: 10, y: 4, w: 280, h: 18, rotation: 0, scaleX: 1, scaleY: 1, size: 14, bold: true, text: "Nickname", color: "#ffffff" },
    ];
  }

  const ICONS = ["Folhinha Particular", "Estampa NPC", "Calça", "Camisa", "Cabelo"];

  const state = {
    FRAME_W: FRAME_DEFAULT.FRAME_W,
    FRAME_H: FRAME_DEFAULT.FRAME_H,
    items: defaultItems(),
    selected: "canvas",
  };

  const stage = document.getElementById("stage");
  const chrome = document.getElementById("chrome");
  const statusEl = document.getElementById("status");
  const out = document.getElementById("out");
  const layersEl = document.getElementById("layers");
  const inspectorEl = document.getElementById("inspector");
  let drag = null;
  let tipEl = null;

  function selectedItem() {
    return state.items.find((it) => it.id === state.selected) || null;
  }

  function round1(n) {
    return Math.round(Number(n) * 10) / 10;
  }

  function applyTransform(el, it) {
    el.style.width = it.w + "px";
    el.style.height = it.h + "px";
    el.style.transform = `translate(${it.x}px, ${it.y}px) rotate(${it.rotation || 0}deg) scale(${it.scaleX || 1}, ${it.scaleY || 1})`;
    el.style.zIndex = String(state.items.indexOf(it) + 1);
  }

  function fillItem(node, it) {
    node.innerHTML = "";
    if (it.kind === "avatar") {
      const box = document.createElement("div");
      box.className = "avatar-box";
      box.style.background = it.fill || "#292929";
      box.style.borderColor = it.stroke || "#222222";
      const ph = document.createElement("div");
      ph.className = "ph";
      ph.textContent = "avatar";
      box.appendChild(ph);
      node.appendChild(box);
    } else if (it.kind === "text") {
      const t = document.createElement("div");
      t.className = "txt bold";
      t.style.fontSize = (it.size || 14) + "px";
      t.textContent = it.text || it.label;
      node.appendChild(t);
    } else if (it.kind === "canvas") {
      const wrap = document.createElement("div");
      wrap.style.display = "flex";
      wrap.style.flexWrap = "wrap";
      wrap.style.gap = "12px";
      wrap.style.padding = "22px 0 0";
      wrap.style.pointerEvents = "none";
      ICONS.forEach((name) => {
        const well = document.createElement("div");
        well.className = "icon-well";
        well.dataset.tip = name;
        wrap.appendChild(well);
      });
      node.appendChild(wrap);
    }
  }

  function attachHandles(node) {
    const rot = document.createElement("div");
    rot.className = "handle-rot";
    rot.dataset.handle = "rot";
    const sc = document.createElement("div");
    sc.className = "handle-scale";
    sc.dataset.handle = "scale";
    node.appendChild(rot);
    node.appendChild(sc);
  }

  function renderStage() {
    const contentH = Math.max(1, state.FRAME_H - 30);
    chrome.style.width = state.FRAME_W + "px";
    stage.style.width = state.FRAME_W + "px";
    stage.style.height = contentH + "px";
    stage.innerHTML = "";
    state.items.forEach((it) => {
      const node = document.createElement("div");
      node.className = "item" + (it.id === state.selected ? " selected" : "");
      node.dataset.id = it.id;
      fillItem(node, it);
      applyTransform(node, it);
      attachHandles(node);
      stage.appendChild(node);
    });
    tipEl = document.createElement("div");
    tipEl.className = "tip-preview";
    stage.appendChild(tipEl);
    renderLayers();
    renderInspector();
  }

  function renderLayers() {
    layersEl.innerHTML = "";
    [...state.items].reverse().forEach((it) => {
      const row = document.createElement("div");
      row.className = "layer-row" + (it.id === state.selected ? " active" : "");
      row.innerHTML = `<span class="kind">${it.kind}</span><span>${it.label}</span>`;
      row.onclick = () => {
        state.selected = it.id;
        renderStage();
      };
      layersEl.appendChild(row);
    });
  }

  function numCtrl(it, key, min, max, step, label) {
    const wrap = document.createElement("label");
    wrap.className = "ctrl";
    wrap.innerHTML = `<span>${label || key}</span>`;
    const range = document.createElement("input");
    range.type = "range";
    range.min = min;
    range.max = max;
    range.step = step;
    range.value = it[key];
    const num = document.createElement("input");
    num.type = "number";
    num.value = it[key];
    const sync = (v) => {
      it[key] = Number(v);
      range.value = it[key];
      num.value = it[key];
      renderStage();
      exportText(false);
    };
    range.oninput = () => sync(range.value);
    num.onchange = () => sync(num.value);
    wrap.appendChild(range);
    wrap.appendChild(num);
    return wrap;
  }

  function renderInspector() {
    const it = selectedItem();
    inspectorEl.innerHTML = "";
    if (!it) {
      inspectorEl.innerHTML = `<div class="status">Selecione um item.</div>`;
      return;
    }
    const title = document.createElement("div");
    title.textContent = `${it.label} (${it.id})`;
    title.style.fontWeight = "700";
    inspectorEl.appendChild(title);
    [["x", -40, 700], ["y", -40, 600], ["w", 40, 700], ["h", 40, 600]].forEach(([k, a, b]) => {
      inspectorEl.appendChild(numCtrl(it, k, a, b, 1, k.toUpperCase()));
    });
  }

  function buildWindowCtrls() {
    const host = document.getElementById("g-window");
    host.innerHTML = "";
    ["FRAME_W", "FRAME_H"].forEach((key) => {
      const wrap = document.createElement("label");
      wrap.className = "ctrl";
      wrap.innerHTML = `<span>${key}</span>`;
      const range = document.createElement("input");
      range.type = "range";
      range.min = key === "FRAME_W" ? 280 : 180;
      range.max = 900;
      range.step = 1;
      range.value = state[key];
      const num = document.createElement("input");
      num.type = "number";
      num.value = state[key];
      const sync = (v) => {
        state[key] = Number(v);
        range.value = state[key];
        num.value = state[key];
        renderStage();
        exportText(false);
      };
      range.oninput = () => sync(range.value);
      num.onchange = () => sync(num.value);
      wrap.appendChild(range);
      wrap.appendChild(num);
      host.appendChild(wrap);
    });
  }

  stage.addEventListener("pointerdown", (e) => {
    const handle = e.target.closest("[data-handle]");
    const node = e.target.closest(".item");
    if (!node) {
      state.selected = null;
      renderStage();
      return;
    }
    const it = state.items.find((x) => x.id === node.dataset.id);
    if (!it) return;
    state.selected = it.id;
    const mode = handle ? handle.dataset.handle : "move";
    drag = {
      mode,
      id: it.id,
      sx: e.clientX,
      sy: e.clientY,
      ox: it.x,
      oy: it.y,
      ow: it.w,
      oh: it.h,
    };
    stage.setPointerCapture(e.pointerId);
    renderStage();
  });

  stage.addEventListener("pointermove", (e) => {
    const well = e.target.closest(".icon-well");
    if (tipEl) {
      if (well && well.dataset.tip) {
        tipEl.style.display = "block";
        tipEl.textContent = well.dataset.tip;
        const r = stage.getBoundingClientRect();
        tipEl.style.left = e.clientX - r.left + 10 + "px";
        tipEl.style.top = e.clientY - r.top + 12 + "px";
      } else {
        tipEl.style.display = "none";
      }
    }
    if (!drag) return;
    const it = state.items.find((x) => x.id === drag.id);
    if (!it) return;
    const dx = e.clientX - drag.sx;
    const dy = e.clientY - drag.sy;
    if (drag.mode === "move") {
      it.x = Math.round(drag.ox + dx);
      it.y = Math.round(drag.oy + dy);
    } else if (drag.mode === "scale") {
      it.w = Math.max(40, Math.round(drag.ow + dx));
      it.h = Math.max(40, Math.round(drag.oh + dy));
    }
    const node = stage.querySelector(`[data-id="${it.id}"]`);
    if (node) applyTransform(node, it);
  });

  stage.addEventListener("pointerup", () => {
    if (drag) {
      drag = null;
      exportText(false);
      renderInspector();
    }
  });

  function moveZ(dir, abs) {
    const i = state.items.findIndex((x) => x.id === state.selected);
    if (i < 0) return;
    const [it] = state.items.splice(i, 1);
    if (abs === "front") state.items.push(it);
    else if (abs === "back") state.items.unshift(it);
    else state.items.splice(Math.max(0, Math.min(state.items.length, i + dir)), 0, it);
    renderStage();
  }

  function addIcon() {
    ICONS.push("Peça extra");
    renderStage();
  }

  function constLine(name, type, value) {
    return `private static const ${name}:${type} = ${value};`;
  }

  function exportText(writeStatus) {
    const s = state;
    const byId = Object.fromEntries(s.items.map((it) => [it.id, it]));
    const avatar = byId.avatar;
    const canvas = byId.canvas;
    const lines = [
      "// Clothes visual editor — cole no chat para aplicar",
      `// frame ${s.FRAME_W} x ${s.FRAME_H}`,
      "",
      constLine("FRAME_W", "int", s.FRAME_W),
      constLine("FRAME_H", "int", s.FRAME_H),
      avatar ? constLine("AVATAR_X", "int", avatar.x) : "",
      avatar ? constLine("AVATAR_Y", "int", avatar.y) : "",
      avatar ? constLine("AVATAR_W", "int", avatar.w) : "",
      avatar ? constLine("AVATAR_H", "int", avatar.h) : "",
      canvas ? `public static var VIEW_W:int = ${Math.round(canvas.w)};` : "",
      canvas ? `public static var VIEW_H:int = ${Math.round(canvas.h)};` : "",
      canvas ? constLine("CANVAS_X", "int", canvas.x) : "",
      canvas ? constLine("CANVAS_Y", "int", canvas.y) : "",
      "",
      JSON.stringify({ FRAME_W: s.FRAME_W, FRAME_H: s.FRAME_H, items: s.items }, null, 2),
    ];
    out.value = lines.filter((x) => x !== undefined).join("\n");
    if (writeStatus) statusEl.textContent = "Export gerado.";
  }

  function loadExport() {
    const raw = out.value;
    const start = raw.lastIndexOf("{");
    if (start < 0) return;
    try {
      const data = JSON.parse(raw.slice(start));
      if (data.FRAME_W) state.FRAME_W = data.FRAME_W;
      if (data.FRAME_H) state.FRAME_H = data.FRAME_H;
      if (data.items) state.items = data.items;
      buildWindowCtrls();
      renderStage();
      statusEl.textContent = "Carregado.";
    } catch {
      statusEl.textContent = "JSON inválido.";
    }
  }

  document.getElementById("btnAddIcon").onclick = addIcon;
  document.getElementById("btnFront").onclick = () => moveZ(0, "front");
  document.getElementById("btnBack").onclick = () => moveZ(0, "back");
  document.getElementById("btnForward").onclick = () => moveZ(1);
  document.getElementById("btnBackward").onclick = () => moveZ(-1);
  document.getElementById("btnDelete").onclick = () => {
    statusEl.textContent = "Remova só no layout do cliente se precisar.";
  };
  document.getElementById("btnExport").onclick = () => exportText(true);
  document.getElementById("btnCopy").onclick = async () => {
    exportText(false);
    try {
      await navigator.clipboard.writeText(out.value);
      statusEl.textContent = "Copiado.";
    } catch {
      out.select();
    }
  };
  document.getElementById("btnApply").onclick = loadExport;
  document.getElementById("btnReset").onclick = () => {
    state.FRAME_W = FRAME_DEFAULT.FRAME_W;
    state.FRAME_H = FRAME_DEFAULT.FRAME_H;
    state.items = defaultItems();
    state.selected = "canvas";
    buildWindowCtrls();
    renderStage();
    exportText(false);
    statusEl.textContent = "Reset.";
  };

  buildWindowCtrls();
  renderStage();
  exportText(false);
  statusEl.textContent = "Redimensione FRAME_W / FRAME_H. Hover nos ícones mostra o nome (preview).";
})();
