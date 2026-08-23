(() => {
  const ASSET = {
    check: "../brand-pack/checkbox.png",
    green: "../brand-pack/illumina_dark_bobba_green.png",
  };

  const FRAME_DEFAULT = { FRAME_W: 404, FRAME_H: 236 };

  function uid(prefix) {
    return prefix + "_" + Math.random().toString(36).slice(2, 7);
  }

  function defaultItems() {
    return [
      { id: "avatar", kind: "avatar", label: "Avatar", x: 6, y: 8, w: 100, h: 160, rotation: 0, scaleX: 1, scaleY: 1, locked: false, fill: "#292929", stroke: "#222222" },
      { id: "name", kind: "text", label: "Nome", x: 118, y: 6, w: 256, h: 18, rotation: 0, scaleX: 1, scaleY: 1, size: 14, bold: true, text: "Nickname", color: "#ffffff" },
      { id: "hint", kind: "text", label: "Motto", x: 122, y: 26, w: 256, h: 16, rotation: 0, scaleX: 1, scaleY: 1, size: 10, bold: false, text: "Motto do usuário", color: "#ffffff" },
      { id: "bar", kind: "bar", label: "Separador", x: 118, y: 48, w: 264, h: 1, rotation: 0, scaleX: 1, scaleY: 1, color: "#3a3b3a" },
      { id: "opts", kind: "grid", label: "Opções", x: 116, y: 55, w: 268, h: 90, rotation: 0, scaleX: 1, scaleY: 1, cols: 2, rows: 4, gapX: 8, gapY: 6, optionSize: 11, color: "#ffffff", cells: [
        "Copiar visual", "Copiar sentar", "Copiar missão", "Copiar danças",
        "Copiar fala", "Copiar ações", "Seguir andar", "Copiar digitando",
      ] },
      { id: "btn_all", kind: "button", label: "Ativar tudo", x: 114, y: 153, w: 132, h: 24, rotation: 0, scaleX: 1, scaleY: 1, caption: "Ativar tudo", size: 11, color: "#ffffff" },
      { id: "btn_none", kind: "button", label: "Desativar tudo", x: 252, y: 153, w: 132, h: 24, rotation: 0, scaleX: 1, scaleY: 1, caption: "Desativar tudo", size: 11, color: "#ffffff" },
    ];
  }

  const state = {
    FRAME_W: FRAME_DEFAULT.FRAME_W,
    FRAME_H: FRAME_DEFAULT.FRAME_H,
    items: defaultItems(),
    selected: "btn_all",
  };

  const imgs = {};
  const stage = document.getElementById("stage");
  const chrome = document.getElementById("chrome");
  const statusEl = document.getElementById("status");
  const out = document.getElementById("out");
  const layersEl = document.getElementById("layers");
  const inspectorEl = document.getElementById("inspector");

  let drag = null;

  function cloneItems(items) {
    return items.map((it) => ({ ...it, cells: it.cells ? [...it.cells] : undefined }));
  }

  function selectedItem() {
    return state.items.find((it) => it.id === state.selected) || null;
  }

  function loadImage(src) {
    return new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => resolve(img);
      img.onerror = () => reject(new Error(src));
      img.src = src;
    });
  }

  function spriteH(sheet, index, count, displayW, displayH) {
    const wrap = document.createElement("div");
    wrap.style.width = displayW + "px";
    wrap.style.height = displayH + "px";
    wrap.style.overflow = "hidden";
    wrap.style.flexShrink = "0";
    wrap.style.imageRendering = "pixelated";
    wrap.style.pointerEvents = "none";
    const i = sheet.cloneNode(true);
    i.draggable = false;
    i.style.display = "block";
    i.style.width = displayW * count + "px";
    i.style.height = displayH + "px";
    i.style.maxWidth = "none";
    i.style.marginLeft = -index * displayW + "px";
    i.style.imageRendering = "pixelated";
    wrap.appendChild(i);
    return wrap;
  }

  function round1(n) {
    return Math.round(Number(n) * 10) / 10;
  }

  function normHex(v, fallback) {
    const s = String(v || fallback || "#ffffff").trim();
    const m = s.match(/^#?([0-9a-fA-F]{6})$/);
    return m ? "#" + m[1].toLowerCase() : (fallback || "#ffffff");
  }

  function hexToAs3(v, fallback) {
    return "0x" + normHex(v, fallback).slice(1);
  }

  function applyTransform(el, it) {
    el.style.width = it.w + "px";
    el.style.height = it.h + "px";
    el.style.transform = `translate(${it.x}px, ${it.y}px) rotate(${it.rotation}deg) scale(${it.scaleX}, ${it.scaleY})`;
    el.style.zIndex = String(state.items.indexOf(it) + 1);
  }

  function fillItem(node, it) {
    node.innerHTML = "";
    if (it.kind === "avatar") {
      const box = document.createElement("div");
      box.className = "avatar-box";
      box.style.background = normHex(it.fill, "#8d8d8d");
      box.style.borderColor = normHex(it.stroke, "#222222");
      const ph = document.createElement("div");
      ph.className = "ph";
      ph.textContent = "avatar";
      box.appendChild(ph);
      node.appendChild(box);
    } else if (it.kind === "text") {
      const t = document.createElement("div");
      t.className = "txt" + (it.bold ? " bold" : "");
      t.style.fontSize = (it.size || 11) + "px";
      t.style.width = "100%";
      t.style.color = normHex(it.color, "#ffffff");
      t.textContent = it.text || it.label;
      node.appendChild(t);
    } else if (it.kind === "bar") {
      const b = document.createElement("div");
      b.className = "bar";
      b.style.background = normHex(it.color, "#31a342");
      node.appendChild(b);
    } else if (it.kind === "button") {
      if (imgs.green) {
        const img = imgs.green.cloneNode(true);
        img.draggable = false;
        img.style.display = "block";
        img.style.width = it.w + "px";
        img.style.height = it.h * 3 + "px";
        img.style.maxWidth = "none";
        img.style.imageRendering = "pixelated";
        img.style.pointerEvents = "none";
        const clip = document.createElement("div");
        clip.style.overflow = "hidden";
        clip.style.width = "100%";
        clip.style.height = "100%";
        clip.style.pointerEvents = "none";
        clip.appendChild(img);
        node.appendChild(clip);
      } else {
        node.style.background = "#2f7a38";
      }
      const cap = document.createElement("div");
      cap.className = "btn-cap";
      cap.style.fontSize = (it.size || 11) + "px";
      cap.style.color = normHex(it.color, "#ffffff");
      cap.textContent = it.caption || it.label;
      node.appendChild(cap);
    } else if (it.kind === "grid") {
      const grid = document.createElement("div");
      grid.className = "grid";
      grid.style.gridTemplateColumns = `repeat(${it.cols || 2}, 1fr)`;
      grid.style.gap = `${it.gapY || 6}px ${it.gapX || 8}px`;
      grid.style.width = "100%";
      grid.style.height = "100%";
      const cells = it.cells || [];
      const n = (it.cols || 2) * (it.rows || 4);
      for (let i = 0; i < n; i++) {
        const row = document.createElement("div");
        row.className = "chk-row";
        if (imgs.check) row.appendChild(spriteH(imgs.check, 0, 2, 18, 18));
        const lbl = document.createElement("span");
        lbl.className = "txt";
        lbl.style.marginLeft = "4px";
        lbl.style.fontSize = (it.optionSize || 11) + "px";
        lbl.style.color = normHex(it.color, "#ffffff");
        lbl.textContent = cells[i] || "Item";
        row.appendChild(lbl);
        grid.appendChild(row);
      }
      node.appendChild(grid);
    }
  }

  function attachHandles(node, it) {
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
      if (it.id === state.selected) attachHandles(node, it);
      applyTransform(node, it);
      stage.appendChild(node);
    });
    renderLayers();
    renderInspector();
  }

  function renderLayers() {
    layersEl.innerHTML = "";
    [...state.items].slice().reverse().forEach((it) => {
      const row = document.createElement("div");
      row.className = "layer-row" + (it.id === state.selected ? " active" : "");
      row.innerHTML = `<span class="kind">${it.kind}</span><span>${it.label || it.id}</span>`;
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
    num.min = min;
    num.max = max;
    num.step = step;
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

  function colorCtrl(it, key, label, fallback) {
    const wrap = document.createElement("label");
    wrap.className = "ctrl color";
    wrap.innerHTML = `<span>${label || key}</span>`;
    const picker = document.createElement("input");
    picker.type = "color";
    picker.value = normHex(it[key], fallback);
    const hex = document.createElement("input");
    hex.type = "text";
    hex.value = picker.value;
    const sync = (v) => {
      it[key] = normHex(v, fallback);
      picker.value = it[key];
      hex.value = it[key];
      renderStage();
      exportText(false);
    };
    picker.oninput = () => sync(picker.value);
    hex.onchange = () => sync(hex.value);
    wrap.appendChild(picker);
    wrap.appendChild(hex);
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
    [["x", -40, 500], ["y", -40, 400], ["w", 8, 420], ["h", 1, 300]].forEach(([k, a, b]) => {
      inspectorEl.appendChild(numCtrl(it, k, a, b, 1, k.toUpperCase()));
    });
    inspectorEl.appendChild(numCtrl(it, "rotation", -180, 180, 1, "ROT"));
    inspectorEl.appendChild(numCtrl(it, "scaleX", 0.2, 3, 0.05, "SX"));
    inspectorEl.appendChild(numCtrl(it, "scaleY", 0.2, 3, 0.05, "SY"));
    if (it.kind === "avatar") {
      inspectorEl.appendChild(colorCtrl(it, "fill", "FILL", "#8d8d8d"));
      inspectorEl.appendChild(colorCtrl(it, "stroke", "STROKE", "#222222"));
    }
    if (it.kind === "text" || it.kind === "bar" || it.kind === "grid" || it.kind === "button") {
      inspectorEl.appendChild(colorCtrl(it, "color", "COR", it.kind === "bar" ? "#31a342" : "#ffffff"));
    }
    if (it.kind === "text" || it.kind === "button") {
      inspectorEl.appendChild(numCtrl(it, "size", 8, 22, 1, "SIZE"));
    }
    if (it.kind === "grid") {
      inspectorEl.appendChild(numCtrl(it, "cols", 1, 4, 1, "COLS"));
      inspectorEl.appendChild(numCtrl(it, "rows", 1, 8, 1, "ROWS"));
      inspectorEl.appendChild(numCtrl(it, "gapX", 0, 24, 1, "GAPX"));
      inspectorEl.appendChild(numCtrl(it, "gapY", 0, 24, 1, "GAPY"));
      inspectorEl.appendChild(numCtrl(it, "optionSize", 8, 16, 1, "FONT"));
    }
    if (it.kind === "text" || it.kind === "button") {
      const lab = document.createElement("label");
      lab.className = "ctrl";
      lab.style.gridTemplateColumns = "72px 1fr";
      lab.innerHTML = `<span>TXT</span>`;
      const inp = document.createElement("input");
      inp.type = "text";
      inp.value = it.caption || it.text || "";
      inp.onchange = () => {
        if (it.kind === "button") it.caption = inp.value;
        else it.text = inp.value;
        it.label = inp.value || it.id;
        renderStage();
        exportText(false);
      };
      lab.appendChild(inp);
      inspectorEl.appendChild(lab);
    }
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
      range.max = 700;
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

  function selectAt(id) {
    state.selected = id;
    renderStage();
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
      or: it.rotation,
      osx: it.scaleX,
      osy: it.scaleY,
    };
    node.setPointerCapture(e.pointerId);
    e.preventDefault();
    renderStage();
  });

  stage.addEventListener("pointermove", (e) => {
    if (!drag) return;
    const it = state.items.find((x) => x.id === drag.id);
    if (!it) return;
    const dx = e.clientX - drag.sx;
    const dy = e.clientY - drag.sy;
    if (drag.mode === "move") {
      it.x = Math.round(drag.ox + dx);
      it.y = Math.round(drag.oy + dy);
    } else if (drag.mode === "scale") {
      it.w = Math.max(8, Math.round(drag.ow + dx));
      it.h = Math.max(1, Math.round(drag.oh + dy));
    } else if (drag.mode === "rot") {
      it.rotation = Math.round(drag.or + dx);
    }
    const node = stage.querySelector(`.item[data-id="${it.id}"]`);
    if (node) applyTransform(node, it);
  });

  function endDrag() {
    if (!drag) return;
    drag = null;
    renderInspector();
    exportText(false);
  }
  stage.addEventListener("pointerup", endDrag);
  stage.addEventListener("pointercancel", endDrag);

  window.addEventListener("keydown", (e) => {
    const it = selectedItem();
    if (!it) return;
    const step = e.shiftKey ? 10 : 1;
    if (["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown"].includes(e.key)) {
      e.preventDefault();
      if (e.key === "ArrowLeft") it.x -= step;
      if (e.key === "ArrowRight") it.x += step;
      if (e.key === "ArrowUp") it.y -= step;
      if (e.key === "ArrowDown") it.y += step;
      renderStage();
      exportText(false);
    }
  });

  function moveZ(delta, extreme) {
    const it = selectedItem();
    if (!it) return;
    const i = state.items.indexOf(it);
    if (extreme === "front") {
      state.items.splice(i, 1);
      state.items.push(it);
    } else if (extreme === "back") {
      state.items.splice(i, 1);
      state.items.unshift(it);
    } else {
      const j = Math.max(0, Math.min(state.items.length - 1, i + delta));
      if (j === i) return;
      state.items.splice(i, 1);
      state.items.splice(j, 0, it);
    }
    renderStage();
    exportText(false);
  }

  function addButton() {
    const it = {
      id: uid("btn"),
      kind: "button",
      label: "Botão",
      x: 110,
      y: 140,
      w: 132,
      h: 24,
      rotation: 0,
      scaleX: 1,
      scaleY: 1,
      caption: "Botão",
      size: 11,
      color: "#ffffff",
      extra: true,
    };
    state.items.push(it);
    state.selected = it.id;
    renderStage();
    exportText(false);
  }

  function addGrid() {
    const it = {
      id: uid("grid"),
      kind: "grid",
      label: "Grid",
      x: 116,
      y: 52,
      w: 268,
      h: 90,
      rotation: 0,
      scaleX: 1,
      scaleY: 1,
      cols: 2,
      rows: 2,
      gapX: 8,
      gapY: 6,
      optionSize: 11,
      color: "#ffffff",
      cells: ["A", "B", "C", "D"],
      extra: true,
    };
    state.items.push(it);
    state.selected = it.id;
    renderStage();
    exportText(false);
  }

  function deleteExtra() {
    const it = selectedItem();
    if (!it || !it.extra) {
      statusEl.textContent = "Só itens extras (botão/grid adicionados) podem ser removidos.";
      return;
    }
    state.items = state.items.filter((x) => x.id !== it.id);
    state.selected = state.items[state.items.length - 1]?.id || null;
    renderStage();
    exportText(false);
  }

  function constLine(name, type, value) {
    return `private static const ${name}:${type} = ${value};`;
  }

  function exportText(writeStatus) {
    const s = state;
    const byId = Object.fromEntries(s.items.map((it) => [it.id, it]));
    const avatar = byId.avatar;
    const name = byId.name;
    const hint = byId.hint;
    const bar = byId.bar;
    const opts = byId.opts;
    const btnAll = byId.btn_all;
    const btnNone = byId.btn_none;
    const extras = s.items.filter((it) => it.extra);
    const canvasX = name ? name.x - 8 : 110;
    const canvasY = name ? name.y - 8 : 0;
    const viewW = bar ? bar.x + bar.w - canvasX + 8 : 280;
    const viewH = btnAll ? btnAll.y - canvasY : 168;

    const lines = [
      "// Mimic visual editor — cole no chat para aplicar em BobbaMimicEditor / BobbaMimicView",
      `// frame ${s.FRAME_W} x ${s.FRAME_H}  (title 30px + content ${s.FRAME_H - 30}px)`,
      "",
      constLine("FRAME_W", "int", s.FRAME_W),
      constLine("FRAME_H", "int", s.FRAME_H),
      avatar ? constLine("AVATAR_X", "int", avatar.x) : "",
      avatar ? constLine("AVATAR_Y", "int", avatar.y) : "",
      avatar ? constLine("AVATAR_W", "int", avatar.w) : "",
      avatar ? constLine("AVATAR_H", "int", avatar.h) : "",
      avatar ? constLine("AVATAR_ROTATION", "Number", round1(avatar.rotation)) : "",
      avatar ? constLine("AVATAR_SCALE_X", "Number", round1(avatar.scaleX)) : "",
      avatar ? constLine("AVATAR_SCALE_Y", "Number", round1(avatar.scaleY)) : "",
      avatar ? constLine("AVATAR_FILL", "uint", hexToAs3(avatar.fill, "#8d8d8d")) : "",
      avatar ? constLine("AVATAR_STROKE", "uint", hexToAs3(avatar.stroke, "#222222")) : "",
      `public static const VIEW_W:int = ${Math.max(1, Math.round(viewW))};`,
      `public static const VIEW_H:int = ${Math.max(1, Math.round(viewH))};`,
      `private static const CANVAS_X:int = ${Math.round(canvasX)};`,
      `private static const CANVAS_Y:int = ${Math.round(canvasY)};`,
    ];
    function emitItem(prefix, it, extraFields) {
      if (!it) return;
      lines.push(constLine(prefix + "_X", "Number", round1(it.x)));
      lines.push(constLine(prefix + "_Y", "Number", round1(it.y)));
      lines.push(constLine(prefix + "_W", "int", Math.round(it.w)));
      lines.push(constLine(prefix + "_H", "int", Math.round(it.h)));
      lines.push(constLine(prefix + "_ROTATION", "Number", round1(it.rotation)));
      lines.push(constLine(prefix + "_SCALE_X", "Number", round1(it.scaleX)));
      lines.push(constLine(prefix + "_SCALE_Y", "Number", round1(it.scaleY)));
      (extraFields || []).forEach(([k, t, v]) => lines.push(constLine(prefix + "_" + k, t, v)));
    }
    emitItem("NAME", name, [["SIZE", "int", name ? name.size : 14], ["COLOR", "uint", hexToAs3(name && name.color, "#ffffff")]]);
    emitItem("HINT", hint, [["SIZE", "int", hint ? hint.size : 11], ["COLOR", "uint", hexToAs3(hint && hint.color, "#ffffff")]]);
    emitItem("BAR", bar, [["COLOR", "uint", hexToAs3(bar && bar.color, "#31a342")]]);
    emitItem("GRID", opts, opts ? [
      ["COLS", "int", opts.cols],
      ["ROWS", "int", opts.rows],
      ["GAP_X", "int", opts.gapX],
      ["GAP_Y", "int", opts.gapY],
      ["OPTION_SIZE", "int", opts.optionSize],
      ["COLOR", "uint", hexToAs3(opts.color, "#ffffff")],
    ] : []);
    emitItem("BTN_ALL", btnAll, [["SIZE", "int", btnAll ? btnAll.size : 11], ["COLOR", "uint", hexToAs3(btnAll && btnAll.color, "#ffffff")]]);
    emitItem("BTN_NONE", btnNone, [["SIZE", "int", btnNone ? btnNone.size : 11], ["COLOR", "uint", hexToAs3(btnNone && btnNone.color, "#ffffff")]]);
    lines.push("");
    lines.push("// z-order (fundo → frente)");
    s.items.forEach((it, i) => lines.push(`// ${i} ${it.kind} ${it.id}  ${it.label}`));
    if (extras.length) {
      lines.push("");
      lines.push("// extras (botões/grids adicionados no editor)");
      extras.forEach((it) => {
        lines.push(`// EXTRA ${it.kind} id=${it.id} x=${it.x} y=${it.y} w=${it.w} h=${it.h} rot=${round1(it.rotation)} sx=${round1(it.scaleX)} sy=${round1(it.scaleY)} z=${s.items.indexOf(it)}`);
      });
    }
    lines.push("");
    lines.push("/* JSON");
    lines.push(JSON.stringify({ FRAME_W: s.FRAME_W, FRAME_H: s.FRAME_H, items: s.items }, null, 2));
    lines.push("*/");
    out.value = lines.filter((x) => x !== "").join("\n");
    if (writeStatus) statusEl.textContent = "Exportado. Copie e cole no chat para aplicar no client.";
  }

  function loadExport() {
    const text = out.value;
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      try {
        const data = JSON.parse(jsonMatch[0]);
        if (data.FRAME_W) state.FRAME_W = data.FRAME_W;
        if (data.FRAME_H) state.FRAME_H = data.FRAME_H;
        if (Array.isArray(data.items)) state.items = cloneItems(data.items);
        buildWindowCtrls();
        renderStage();
        exportText(false);
        statusEl.textContent = "JSON carregado.";
        return;
      } catch (_) {}
    }
    statusEl.textContent = "Cole o bloco JSON do export.";
  }

  document.getElementById("btnAddButton").onclick = addButton;
  document.getElementById("btnAddGrid").onclick = addGrid;
  document.getElementById("btnFront").onclick = () => moveZ(0, "front");
  document.getElementById("btnBack").onclick = () => moveZ(0, "back");
  document.getElementById("btnForward").onclick = () => moveZ(1);
  document.getElementById("btnBackward").onclick = () => moveZ(-1);
  document.getElementById("btnDelete").onclick = deleteExtra;
  document.getElementById("btnExport").onclick = () => exportText(true);
  document.getElementById("btnCopy").onclick = async () => {
    exportText(false);
    try {
      await navigator.clipboard.writeText(out.value);
      statusEl.textContent = "Copiado. Cole no chat para aplicar.";
    } catch {
      out.select();
      statusEl.textContent = "Selecione e copie o texto.";
    }
  };
  document.getElementById("btnApply").onclick = loadExport;
  document.getElementById("btnReset").onclick = () => {
    state.FRAME_W = FRAME_DEFAULT.FRAME_W;
    state.FRAME_H = FRAME_DEFAULT.FRAME_H;
    state.items = defaultItems();
    state.selected = "avatar";
    buildWindowCtrls();
    renderStage();
    exportText(false);
    statusEl.textContent = "Reset.";
  };

  buildWindowCtrls();
  Promise.allSettled([
    loadImage(ASSET.check).then((img) => { imgs.check = img; }),
    loadImage(ASSET.green).then((img) => { imgs.green = img; }),
  ]).then((results) => {
    const failed = [];
    if (results[0].status === "rejected") failed.push("checkbox");
    if (results[1].status === "rejected") failed.push("green btn");
    statusEl.textContent = failed.length
      ? "Assets falharam: " + failed.join(", ")
      : "Arraste os itens, depois Exportar / Copiar.";
    renderStage();
    exportText(false);
  });
})();
