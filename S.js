// ==UserScript==
// @name         Block "Open in App" banners & redirects
// @namespace    user
// @match        *://*/*
// @run-at       document-start
// ==/UserScript==

(function() {
    const removePatterns = [
        /open in app/i,
        /app promotion/i,
        /install app/i,
        /download on the app store/i,
        /continue in app/i
    ];
    const blockRedirects = [
        /smartbanner/i,
        /deeplink/i,
        /universal-link/i
    ];

    // Remove banner elements once DOM is ready
    const observer = new MutationObserver((mutations) => {
        for (const m of mutations) {
            for (const node of m.addedNodes) {
                if (node.nodeType === 1) {
                    const text = node.textContent || "";
                    if (removePatterns.some(p => p.test(text))) {
                        node.remove();
                        continue;
                    }
                    // remove elements with app-banner classes/ids
                    const idcls = (node.id + " " + node.className).toLowerCase();
                    if (blockRedirects.some(p => p.test(idcls))) {
                        node.remove();
                    }
                }
            }
        }
    });
    observer.observe(document.documentElement, { childList: true, subtree: true });

    // Override redirect attempts
    const noop = function(e) { e.stopImmediatePropagation(); e.preventDefault(); };
    document.addEventListener("click", (e) => {
        const tgt = e.target.closest("a[href]");
        if (tgt) {
            const href = tgt.getAttribute("href");
            // block deep link schemas
            if (/^(intent:|app:\/\/|.+:\/\/.+\?app_open=1)/i.test(href)) {
                e.preventDefault();
                e.stopPropagation();
                return false;
            }
        }
    }, true);
})();
