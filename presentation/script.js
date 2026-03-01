const slideLinks = Array.from(document.querySelectorAll('.slide-link'));
const slides = Array.from(document.querySelectorAll('.slide'));
const status = document.getElementById('slideStatus');
const prevBtn = document.getElementById('prevBtn');
const nextBtn = document.getElementById('nextBtn');

let current = 0;

function setSlide(index) {
  if (index < 0 || index >= slides.length) return;
  current = index;

  slides.forEach((slide, i) => {
    slide.classList.toggle('active', i === current);
  });

  slideLinks.forEach((btn, i) => {
    btn.classList.toggle('active', i === current);
  });

  status.textContent = `Слайд ${current + 1} / ${slides.length}`;
  prevBtn.disabled = current === 0;
  nextBtn.disabled = current === slides.length - 1;

  const activeLink = slideLinks[current];
  activeLink.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
}

slideLinks.forEach((btn, i) => {
  btn.addEventListener('click', () => setSlide(i));
});

prevBtn.addEventListener('click', () => setSlide(current - 1));
nextBtn.addEventListener('click', () => setSlide(current + 1));

document.addEventListener('keydown', (e) => {
  // Don't change slides while a modal is open
  if (document.querySelector('.modal.show')) return;
  if (e.key === 'ArrowRight') setSlide(current + 1);
  if (e.key === 'ArrowLeft') setSlide(current - 1);
});

// Screenshot modal wiring
const screenshotModal = document.getElementById('screenshotModal');
const screenshotModalLabel = document.getElementById('screenshotModalLabel');
const screenshotModalImg = document.getElementById('screenshotModalImg');

function openScreenshotModalWith(src, title) {
  if (!screenshotModal) return;

  const safeTitle = title || 'Screenshot';
  if (screenshotModalLabel) screenshotModalLabel.textContent = safeTitle;

  if (screenshotModalImg) {
    screenshotModalImg.src = src || '';
    screenshotModalImg.alt = safeTitle;
    resetScreenshotZoom();
  }

  // For links we rely on data-bs-toggle, but for <img> clicks we open programmatically
  if (window.bootstrap?.Modal) {
    const modal = window.bootstrap.Modal.getOrCreateInstance(screenshotModal);
    modal.show();
  }
}

let screenshotZoom = 1;
const ZOOM_MIN = 1;
const ZOOM_MAX = 4;
const ZOOM_STEP = 0.15;

function applyScreenshotZoom() {
  if (!screenshotModalImg) return;

  const clamped = Math.min(ZOOM_MAX, Math.max(ZOOM_MIN, screenshotZoom));
  screenshotZoom = clamped;

  // Use width scaling (not CSS transform) so the modal body can scroll
  if (screenshotZoom <= 1) {
    screenshotModalImg.style.width = '100%';
    screenshotModalImg.style.maxWidth = '100%';
    screenshotModalImg.style.cursor = 'zoom-in';
  } else {
    screenshotModalImg.style.width = `${screenshotZoom * 100}%`;
    screenshotModalImg.style.maxWidth = 'none';
    screenshotModalImg.style.cursor = 'zoom-out';
  }
}

function resetScreenshotZoom() {
  screenshotZoom = 1;
  applyScreenshotZoom();
  // Reset scroll position if we have a modal-body
  const body = screenshotModal?.querySelector('.modal-body');
  if (body) {
    body.scrollTop = 0;
    body.scrollLeft = 0;
  }
}

document.addEventListener('click', (e) => {
  const link = e.target.closest('.screenshot-link');
  if (!link) return;

  // Avoid jumping to top because of href="#"
  e.preventDefault();

  const img = link.getAttribute('data-img');
  const title = link.getAttribute('data-title') || 'Screenshot';

  // If modal isn't auto-opened (or to ensure consistent behavior), we can open it ourselves.
  // When using data-bs-toggle this will just show the same modal instance.
  openScreenshotModalWith(img, title);
});

// Click-to-open for images inside slides
document.addEventListener('click', (e) => {
  const imgEl = e.target.closest('main .slide img');
  if (!imgEl) return;

  // Ignore modal image itself if event bubbles in edge cases
  if (imgEl.id === 'screenshotModalImg') return;

  const src = imgEl.getAttribute('src');
  if (!src) return;

  // Avoid opening on decorative/empty alt
  const title = imgEl.getAttribute('alt') || 'Screenshot';
  openScreenshotModalWith(src, title);
});

if (screenshotModalImg) {
  // Zoom with mouse wheel inside the modal
  const modalBody = screenshotModal?.querySelector('.modal-body');
  modalBody?.addEventListener(
    'wheel',
    (e) => {
      // Only when a screenshot is loaded and cursor is over the image
      if (!screenshotModalImg.src) return;
      if (!e.target.closest('#screenshotModalImg')) return;

      e.preventDefault();
      const direction = Math.sign(e.deltaY);
      screenshotZoom += direction > 0 ? -ZOOM_STEP : ZOOM_STEP;
      applyScreenshotZoom();
    },
    { passive: false }
  );

  screenshotModal?.addEventListener('hidden.bs.modal', () => {
    // Release memory and avoid showing stale content next time
    screenshotModalImg.src = '';
    resetScreenshotZoom();
  });
}

setSlide(0);
