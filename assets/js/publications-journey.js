// Publications page (_includes/publications_journey.liquid): the
// "Journey | Classic list" switch and the chapter filter chips.
// Without this script the page shows everything (journey, then the classic list).
(function () {
  var root = document.getElementById("jr-root");
  if (!root) return;
  var KEY = "publications-view";

  function press(buttons, attr, value) {
    for (var i = 0; i < buttons.length; i++) {
      buttons[i].setAttribute("aria-pressed", buttons[i].getAttribute(attr) === value ? "true" : "false");
    }
  }

  var viewButtons = root.querySelectorAll("[data-jr-view]");
  function setView(view, save) {
    root.setAttribute("data-view", view);
    press(viewButtons, "data-jr-view", view);
    if (save) {
      try {
        window.localStorage.setItem(KEY, view);
      } catch (e) {}
    }
  }

  var chips = root.querySelectorAll("[data-jr-filter]");
  var parts = root.querySelectorAll(".jr-chapter, .jr-side");
  function setFilter(f) {
    root.setAttribute("data-filter", f);
    press(chips, "data-jr-filter", f);
    for (var i = 0; i < parts.length; i++) {
      var ch = parts[i].getAttribute("data-chapter");
      parts[i].hidden = f !== "all" && ch !== f;
    }
  }

  for (var i = 0; i < viewButtons.length; i++) {
    viewButtons[i].addEventListener("click", function () {
      setView(this.getAttribute("data-jr-view"), true);
    });
  }
  for (var j = 0; j < chips.length; j++) {
    chips[j].addEventListener("click", function () {
      setFilter(this.getAttribute("data-jr-filter"));
    });
  }

  setView(root.getAttribute("data-view") === "classic" ? "classic" : "journey", false);
  setFilter("all");
})();
