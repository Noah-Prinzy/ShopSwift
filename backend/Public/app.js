// -----------------------------------------------------------------------------
// ShopSwift browser PWA
// The browser layer owns presentation and navigation only. Accounts, catalog,
// cart, stock and checkout remain owned by the existing Vapor REST API.
//
// Short notes:
// - `api(path, options)`: centralized helper that adds Bearer token and parses errors.
// - UI state is kept in `state`; views render from state and call API helper functions.
// - The app intentionally keeps API responses uncached so inventory and account data are fresh.
// -----------------------------------------------------------------------------

const state = {
  token: localStorage.getItem('shopswift.token'),
  user: null,
  categories: [],
  featuredProducts: [],
  catalogProducts: [],
  cart: { items: [], total: 0 },
  catalogRequest: 0
};

const money = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' });
const $ = (id) => document.getElementById(id);
const pageNames = ['home', 'shop', 'categories', 'product', 'cart', 'login', 'signup', 'profile'];
const categoryIconIDs = {
  phones: 'icon-phone', smartphones: 'icon-phone', computers: 'icon-laptop', laptops: 'icon-laptop',
  audio: 'icon-audio', wearables: 'icon-watch', accessories: 'icon-keyboard', keyboards: 'icon-keyboard'
};

class APIRequestError extends Error {
  constructor(message, status) {
    super(message);
    this.name = 'APIRequestError';
    this.status = status;
  }
}

// Sends the stored bearer token only when present and exposes Vapor's `reason`
// message so forms never claim success after a backend rejection.
async function api(path, options = {}) {
  const headers = { Accept: 'application/json', ...(options.headers || {}) };
  if (options.body) headers['Content-Type'] = 'application/json';
  if (state.token) headers.Authorization = `Bearer ${state.token}`;

  let response;
  try {
    response = await fetch(path, { ...options, headers });
  } catch (_) {
    throw new APIRequestError('ShopSwift could not reach the server. Check that the Vapor backend is running.', 0);
  }

  if (!response.ok) {
    let reason = `The server returned status ${response.status}.`;
    try { reason = (await response.json()).reason || reason; } catch (_) { /* non-JSON response */ }
    throw new APIRequestError(reason, response.status);
  }
  if (response.status === 204) return null;
  return response.json();
}

function iconMarkup(id) {
  return `<svg aria-hidden="true"><use href="#${id}"></use></svg>`;
}

function escapeHTML(value = '') {
  const div = document.createElement('div');
  div.textContent = String(value);
  return div.innerHTML;
}

function setButtonBusy(button, busy, busyText) {
  if (!button.dataset.label) button.dataset.label = button.textContent.trim();
  button.disabled = busy;
  if (busy) button.textContent = busyText;
  else button.textContent = button.dataset.label;
}

function showToast(message, type = 'success') {
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = iconMarkup(type === 'error' ? 'icon-close' : 'icon-check');
  const copy = document.createElement('p');
  copy.textContent = message;
  toast.append(copy);
  $('toast-region').append(toast);
  window.setTimeout(() => toast.remove(), 4200);
}

function stateBlock({ title, message, icon = 'icon-bag', actionLabel, onAction }) {
  const block = document.createElement('div');
  block.className = 'state-block';
  block.innerHTML = `${iconMarkup(icon)}<h3>${escapeHTML(title)}</h3><p>${escapeHTML(message)}</p>`;
  if (actionLabel) {
    const button = document.createElement('button');
    button.className = 'button button-dark';
    button.type = 'button';
    button.textContent = actionLabel;
    button.addEventListener('click', onAction);
    block.append(button);
  }
  return block;
}

function renderSkeletons(container, count = 4) {
  container.replaceChildren(...Array.from({ length: count }, () => {
    const card = document.createElement('div');
    card.className = 'skeleton-card';
    card.innerHTML = '<div class="skeleton-image"></div><div class="skeleton-line short"></div><div class="skeleton-line"></div>';
    return card;
  }));
}

function saveAuth(auth) {
  state.token = auth.token;
  state.user = auth.user;
  localStorage.setItem('shopswift.token', auth.token);
  updateAccountNavigation();
}

function clearAuth() {
  state.token = null;
  state.user = null;
  state.cart = { items: [], total: 0 };
  localStorage.removeItem('shopswift.token');
  updateCartCount();
  updateAccountNavigation();
}

function updateAccountNavigation() {
  const authenticated = Boolean(state.token && state.user);
  $('account-link').href = authenticated ? '#profile' : '#login';
  $('account-link').ariaLabel = authenticated ? `Account: ${state.user.username}` : 'Sign in';
  $('mobile-account-link').href = authenticated ? '#profile' : '#login';
  $('mobile-account-link').dataset.nav = authenticated ? 'profile' : 'login';
  $('mobile-account-link').firstChild.textContent = authenticated ? 'Profile ' : 'Sign in ';
}

function updateCartCount() {
  const count = state.cart.items.reduce((total, item) => total + item.quantity, 0);
  $('cart-count').textContent = String(count);
  $('cart-count').setAttribute('aria-label', `${count} ${count === 1 ? 'item' : 'items'} in cart`);
}

function getRoute() {
  const raw = (location.hash || '#home').slice(1);
  const [path, queryString = ''] = raw.split('?');
  const [name, value] = path.split('/');
  return {
    name: pageNames.includes(name) ? name : 'home',
    value: value ? decodeURIComponent(value) : null,
    query: new URLSearchParams(queryString)
  };
}

// Hash routing keeps the PWA deployable behind Vapor without server-side page
// rewrites. Dynamic product routes still fetch the canonical REST resource.
async function route() {
  closeMobileMenu();
  const current = getRoute();
  pageNames.forEach((name) => $(`${name}-page`).classList.toggle('hidden', name !== current.name));
  document.querySelectorAll('[data-nav]').forEach((link) => {
    link.classList.toggle('active', link.dataset.nav === current.name || (current.name === 'product' && link.dataset.nav === 'shop'));
  });
  window.scrollTo({ top: 0, behavior: 'instant' });

  const titles = { home: 'Modern Electronics', shop: 'Shop', categories: 'Categories', product: 'Product', cart: 'Cart', login: 'Sign In', signup: 'Create Account', profile: 'Profile' };
  document.title = `${titles[current.name]} — ShopSwift`;

  if (current.name === 'shop') {
    const category = current.query.get('category') || '';
    const search = current.query.get('q') || '';
    $('category-select').value = state.categories.includes(category) ? category : '';
    $('search-input').value = search;
    await loadCatalog({ category, search });
  }
  if (current.name === 'product') await loadProductDetail(current.value);
  if (current.name === 'cart') await showCartPage();
  if (current.name === 'profile') showProfilePage();
}

function categoryIcon(category) {
  return categoryIconIDs[category.toLowerCase()] || 'icon-grid';
}

function imageFallback(image, wrapper) {
  image.addEventListener('error', () => {
    image.removeAttribute('src');
    wrapper.classList.add('image-error');
  }, { once: true });
  if (!image.getAttribute('src')) wrapper.classList.add('image-error');
}

function createProductCard(product) {
  const fragment = $('product-card-template').content.cloneNode(true);
  const card = fragment.querySelector('.product-card');
  const imageLink = fragment.querySelector('.product-image-link');
  const image = fragment.querySelector('.product-image');
  const detailHash = `#product/${encodeURIComponent(product.id)}`;

  imageLink.href = detailHash;
  image.src = product.imageURL || '';
  image.alt = product.name;
  imageFallback(image, imageLink);
  fragment.querySelector('.product-category').textContent = product.category;
  const nameLink = fragment.querySelector('.product-name');
  nameLink.href = detailHash;
  nameLink.textContent = product.name;
  fragment.querySelector('.product-description').textContent = product.description;
  fragment.querySelector('.product-price').textContent = money.format(product.price);

  const stock = fragment.querySelector('.stock-pill');
  stock.textContent = product.stock > 0 ? `${product.stock} in stock` : 'Sold out';
  stock.classList.toggle('sold-out', product.stock <= 0);

  const button = fragment.querySelector('.add-button');
  button.disabled = product.stock <= 0;
  if (product.stock <= 0) button.querySelector('span').textContent = 'Sold out';
  button.addEventListener('click', async () => {
    button.disabled = true;
    try { await addToCart(product.id, 1); }
    finally { button.disabled = product.stock <= 0; }
  });
  card.dataset.productId = product.id;
  return fragment;
}

function renderProductCollection(container, products, emptyCopy = 'No products match those filters.') {
  if (!products.length) {
    container.replaceChildren(stateBlock({
      title: 'No products found', message: emptyCopy, icon: 'icon-search', actionLabel: 'Clear filters',
      onAction: () => { location.hash = '#shop'; }
    }));
    return;
  }
  container.replaceChildren(...products.map(createProductCard));
}

function renderHeroAndFeatured() {
  const available = state.featuredProducts.filter((product) => product.stock > 0);
  const heroProduct = available[0] || state.featuredProducts[0];
  if (heroProduct) {
    $('hero-image').src = heroProduct.imageURL || '';
    $('hero-image').alt = heroProduct.name;
    $('hero-product-name').textContent = heroProduct.name;
    $('hero-product-label').classList.remove('hidden');
  }
  renderProductCollection($('featured-grid'), state.featuredProducts.slice(0, 4), 'The featured catalog is currently empty.');
}

function createCategoryTile(category) {
  const count = state.featuredProducts.filter((product) => product.category === category).length;
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'category-tile';
  button.innerHTML = `<span class="category-icon">${iconMarkup(categoryIcon(category))}</span><strong>${escapeHTML(category)}</strong>`;
  button.title = count ? `${count} ${count === 1 ? 'product' : 'products'}` : `Browse ${category}`;
  button.addEventListener('click', () => openCategory(category));
  return button;
}

function createCategoryCard(category) {
  const count = state.featuredProducts.filter((product) => product.category === category).length;
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'category-card';
  button.innerHTML = `${iconMarkup(categoryIcon(category))}<span class="corner-arrow">${iconMarkup('icon-arrow')}</span><div><h2>${escapeHTML(category)}</h2><p>${count} ${count === 1 ? 'product' : 'products'} available</p></div>`;
  button.addEventListener('click', () => openCategory(category));
  return button;
}

function renderCategories() {
  const homeList = $('home-category-list');
  const grid = $('category-grid');
  if (!state.categories.length) {
    const empty = stateBlock({ title: 'No categories yet', message: 'Categories will appear when the API returns catalog data.' });
    homeList.replaceChildren(empty.cloneNode(true));
    grid.replaceChildren(empty);
    return;
  }
  homeList.replaceChildren(...state.categories.slice(0, 6).map(createCategoryTile));
  grid.replaceChildren(...state.categories.map(createCategoryCard));

  const select = $('category-select');
  const previous = select.value;
  select.querySelectorAll('option:not(:first-child)').forEach((option) => option.remove());
  state.categories.forEach((category) => select.add(new Option(category, category)));
  if (state.categories.includes(previous)) select.value = previous;
}

function openCategory(category) {
  location.hash = `#shop?category=${encodeURIComponent(category)}`;
}

async function loadInitialCatalog() {
  renderSkeletons($('featured-grid'), 4);
  try {
    const [products, categories] = await Promise.all([
      api('/api/v1/products'),
      api('/api/v1/categories')
    ]);
    state.featuredProducts = products;
    state.categories = categories;
    renderHeroAndFeatured();
    renderCategories();
  } catch (error) {
    $('featured-grid').replaceChildren(stateBlock({
      title: 'Catalog unavailable', message: error.message, icon: 'icon-refresh', actionLabel: 'Try again', onAction: loadInitialCatalog
    }));
    $('home-category-list').replaceChildren();
    $('category-grid').replaceChildren(stateBlock({ title: 'Categories unavailable', message: error.message, icon: 'icon-refresh' }));
  }
}

async function loadCatalog({ category = $('category-select').value, search = $('search-input').value.trim() } = {}) {
  const requestID = ++state.catalogRequest;
  const grid = $('product-grid');
  renderSkeletons(grid, 8);
  const query = new URLSearchParams();
  if (category) query.set('category', category);
  if (search) query.set('q', search);

  try {
    const products = await api(`/api/v1/products${query.size ? `?${query}` : ''}`);
    if (requestID !== state.catalogRequest) return;
    state.catalogProducts = products;
    const context = [search && `matching “${search}”`, category && `in ${category}`].filter(Boolean).join(' ');
    $('catalog-summary').textContent = `${products.length} ${products.length === 1 ? 'product' : 'products'} ${context || 'available across the catalog'}.`;
    renderProductCollection(grid, products);
  } catch (error) {
    if (requestID !== state.catalogRequest) return;
    grid.replaceChildren(stateBlock({
      title: 'Could not load products', message: error.message, icon: 'icon-refresh', actionLabel: 'Try again',
      onAction: () => loadCatalog({ category, search })
    }));
  }
}

async function loadProductDetail(productID) {
  const container = $('product-detail');
  if (!productID) {
    container.replaceChildren(stateBlock({ title: 'Product not found', message: 'No product was selected.', actionLabel: 'Return to shop', onAction: () => { location.hash = '#shop'; } }));
    return;
  }
  container.replaceChildren(stateBlock({ title: 'Loading product', message: 'Fetching the latest price and stock from ShopSwift…', icon: 'icon-refresh' }));

  try {
    const product = await api(`/api/v1/products/${encodeURIComponent(productID)}`);
    let quantity = 1;
    const imageWrap = document.createElement('div');
    imageWrap.className = 'detail-image-wrap';
    imageWrap.innerHTML = `<img alt="${escapeHTML(product.name)}"><span class="image-fallback">${iconMarkup('icon-bag')}<span>Image unavailable</span></span>`;
    const image = imageWrap.querySelector('img');
    image.src = product.imageURL || '';
    imageFallback(image, imageWrap);

    const copy = document.createElement('div');
    copy.className = 'detail-copy';
    copy.innerHTML = `
      <p class="product-category">${escapeHTML(product.category)}</p>
      <h1>${escapeHTML(product.name)}</h1>
      <strong class="detail-price">${money.format(product.price)}</strong>
      <p class="detail-description">${escapeHTML(product.description)}</p>
      <p class="stock-line ${product.stock <= 0 ? 'out' : ''}"><span class="stock-dot"></span>${product.stock > 0 ? `${product.stock} units available` : 'Currently out of stock'}</p>
      <div class="detail-actions">
        <div class="quantity-control" aria-label="Quantity">
          <button class="quantity-minus" type="button" aria-label="Decrease quantity">${iconMarkup('icon-minus')}</button>
          <span class="quantity-value">1</span>
          <button class="quantity-plus" type="button" aria-label="Increase quantity">${iconMarkup('icon-plus')}</button>
        </div>
        <button class="button button-primary detail-add" type="button">${product.stock > 0 ? 'Add to cart' : 'Out of stock'} ${iconMarkup('icon-cart')}</button>
      </div>`;

    const value = copy.querySelector('.quantity-value');
    const minus = copy.querySelector('.quantity-minus');
    const plus = copy.querySelector('.quantity-plus');
    const add = copy.querySelector('.detail-add');
    const refreshQuantity = () => {
      value.textContent = String(quantity);
      minus.disabled = quantity <= 1;
      plus.disabled = quantity >= product.stock;
    };
    minus.addEventListener('click', () => { quantity = Math.max(1, quantity - 1); refreshQuantity(); });
    plus.addEventListener('click', () => { quantity = Math.min(product.stock, quantity + 1); refreshQuantity(); });
    add.disabled = product.stock <= 0;
    add.addEventListener('click', async () => {
      add.disabled = true;
      try { await addToCart(product.id, quantity); }
      finally { add.disabled = product.stock <= 0; }
    });
    refreshQuantity();
    container.replaceChildren(imageWrap, copy);
    document.title = `${product.name} — ShopSwift`;
  } catch (error) {
    container.replaceChildren(stateBlock({
      title: error.status === 404 ? 'Product not found' : 'Could not load this product', message: error.message,
      icon: 'icon-refresh', actionLabel: 'Back to shop', onAction: () => { location.hash = '#shop'; }
    }));
  }
}

async function addToCart(productID, quantity) {
  if (!state.token || !state.user) {
    showToast('Sign in to add products to your cart.', 'error');
    location.hash = '#login';
    return false;
  }
  try {
    state.cart = await api('/api/v1/cart/items', {
      method: 'POST', body: JSON.stringify({ productID, quantity })
    });
    updateCartCount();
    showToast(quantity === 1 ? 'Product added to your cart.' : `${quantity} products added to your cart.`);
    return true;
  } catch (error) {
    if (error.status === 401) clearAuth();
    showToast(error.message, 'error');
    return false;
  }
}

async function loadCart() {
  state.cart = await api('/api/v1/cart');
  updateCartCount();
  renderCart();
}

function authGuard(container, subject) {
  container.innerHTML = `${iconMarkup(subject === 'cart' ? 'icon-cart' : 'icon-user')}<h2>Sign in to view your ${subject}</h2><p>Your ${subject} is connected to your ShopSwift account and the Vapor API.</p><a class="button button-primary" href="#login">Sign in</a><a class="text-link" href="#signup">Create an account</a>`;
}

async function showCartPage() {
  const guard = $('cart-guard');
  const content = $('cart-content');
  if (!state.token || !state.user) {
    authGuard(guard, 'cart');
    guard.classList.remove('hidden');
    content.classList.add('hidden');
    return;
  }
  guard.classList.add('hidden');
  content.classList.remove('hidden');
  $('cart-list').replaceChildren(stateBlock({ title: 'Loading your cart', message: 'Checking current quantities and stock…', icon: 'icon-refresh' }));
  try { await loadCart(); }
  catch (error) {
    if (error.status === 401) { clearAuth(); return showCartPage(); }
    $('cart-list').replaceChildren(stateBlock({ title: 'Could not load your cart', message: error.message, icon: 'icon-refresh', actionLabel: 'Try again', onAction: showCartPage }));
  }
}

function renderCart() {
  const list = $('cart-list');
  $('cart-subtotal').textContent = money.format(state.cart.total);
  $('cart-total').textContent = money.format(state.cart.total);
  $('checkout-button').disabled = state.cart.items.length === 0;
  if (!state.cart.items.length) {
    list.replaceChildren(stateBlock({
      title: 'Your cart is empty', message: 'Browse the catalog and add something you will love.', icon: 'icon-cart', actionLabel: 'Start shopping',
      onAction: () => { location.hash = '#shop'; }
    }));
    return;
  }

  list.replaceChildren(...state.cart.items.map((item) => {
    const row = document.createElement('article');
    row.className = 'cart-item';
    const imageWrap = document.createElement('a');
    imageWrap.className = 'cart-item-image';
    imageWrap.href = `#product/${encodeURIComponent(item.product.id)}`;
    const image = document.createElement('img');
    image.src = item.product.imageURL || '';
    image.alt = item.product.name;
    image.addEventListener('error', () => { image.style.display = 'none'; imageWrap.innerHTML = iconMarkup('icon-bag'); }, { once: true });
    imageWrap.append(image);

    const main = document.createElement('div');
    main.className = 'cart-item-main';
    main.innerHTML = `<p class="product-category">${escapeHTML(item.product.category)}</p><h3><a href="#product/${encodeURIComponent(item.product.id)}">${escapeHTML(item.product.name)}</a></h3><span class="cart-unit-price">${money.format(item.product.price)} each</span>`;

    const actions = document.createElement('div');
    actions.className = 'cart-item-actions';
    const total = document.createElement('strong');
    total.className = 'cart-line-total';
    total.textContent = money.format(item.lineTotal);
    const controls = document.createElement('div');
    controls.className = 'cart-controls';
    controls.innerHTML = `<div class="quantity-control"><button class="minus" type="button" aria-label="Decrease ${escapeHTML(item.product.name)} quantity">${iconMarkup('icon-minus')}</button><span>${item.quantity}</span><button class="plus" type="button" aria-label="Increase ${escapeHTML(item.product.name)} quantity">${iconMarkup('icon-plus')}</button></div><button class="remove-button" type="button" aria-label="Remove ${escapeHTML(item.product.name)}">${iconMarkup('icon-trash')}</button>`;
    const minus = controls.querySelector('.minus');
    const plus = controls.querySelector('.plus');
    minus.disabled = item.quantity <= 1;
    plus.disabled = item.quantity >= item.product.stock;
    minus.addEventListener('click', () => updateCartItem(item.id, item.quantity - 1));
    plus.addEventListener('click', () => updateCartItem(item.id, item.quantity + 1));
    controls.querySelector('.remove-button').addEventListener('click', () => removeCartItem(item.id));
    actions.append(total, controls);
    row.append(imageWrap, main, actions);
    return row;
  }));
}

async function updateCartItem(itemID, quantity) {
  try {
    state.cart = await api(`/api/v1/cart/items/${encodeURIComponent(itemID)}`, {
      method: 'PATCH', body: JSON.stringify({ quantity })
    });
    updateCartCount();
    renderCart();
  } catch (error) { showToast(error.message, 'error'); }
}

async function removeCartItem(itemID) {
  try {
    state.cart = await api(`/api/v1/cart/items/${encodeURIComponent(itemID)}`, { method: 'DELETE' });
    updateCartCount();
    renderCart();
    showToast('Product removed from your cart.');
  } catch (error) { showToast(error.message, 'error'); }
}

async function checkout() {
  const button = $('checkout-button');
  setButtonBusy(button, true, 'Processing…');
  try {
    const order = await api('/api/v1/orders/checkout', { method: 'POST' });
    state.cart = { items: [], total: 0 };
    updateCartCount();
    renderCart();
    $('checkout-dialog-message').textContent = `Order ${String(order.id).slice(0, 8)} has been recorded. No payment was collected.`;
    if (typeof $('checkout-dialog').showModal === 'function') $('checkout-dialog').showModal();
    else showToast('Prototype checkout completed.');
    await loadInitialCatalog(); // Checkout may reduce product stock.
  } catch (error) { showToast(error.message, 'error'); }
  finally { setButtonBusy(button, false); button.disabled = state.cart.items.length === 0; }
}

function fillProfile() {
  if (!state.user) return;
  $('profile-username').value = state.user.username;
  $('profile-email').value = state.user.email;
  $('profile-display-name').textContent = state.user.username;
  $('profile-display-email').textContent = state.user.email;
  $('profile-avatar').textContent = state.user.username.charAt(0) || 'S';
}

function showProfilePage() {
  const guard = $('profile-guard');
  const content = $('profile-content');
  if (!state.token || !state.user) {
    authGuard(guard, 'profile');
    guard.classList.remove('hidden');
    content.classList.add('hidden');
    return;
  }
  guard.classList.add('hidden');
  content.classList.remove('hidden');
  fillProfile();
}

async function restoreSession() {
  if (!state.token) { updateAccountNavigation(); return; }
  try {
    state.user = await api('/api/v1/profile');
    updateAccountNavigation();
    await loadCart();
  } catch (_) { clearAuth(); }
}

function validateForm(form, messageElement, extraValidation) {
  form.querySelectorAll('input').forEach((input) => input.classList.remove('invalid'));
  if (!form.checkValidity()) {
    const invalid = form.querySelector(':invalid');
    if (invalid) invalid.classList.add('invalid');
    messageElement.textContent = invalid?.validationMessage || 'Please check the form fields.';
    invalid?.focus();
    return false;
  }
  if (extraValidation) return extraValidation();
  return true;
}

function setMessage(element, message, success = false) {
  element.textContent = message;
  element.classList.toggle('success', success);
}

function submitCatalogFilters() {
  const query = new URLSearchParams();
  const search = $('search-input').value.trim();
  const category = $('category-select').value;
  if (search) query.set('q', search);
  if (category) query.set('category', category);
  const nextHash = `#shop${query.size ? `?${query}` : ''}`;
  if (location.hash === nextHash) loadCatalog({ search, category });
  else location.hash = nextHash;
}

function submitGlobalSearch(input) {
  const search = input.value.trim();
  location.hash = `#shop${search ? `?q=${encodeURIComponent(search)}` : ''}`;
  input.value = '';
  $('mobile-search-form').classList.remove('open');
}

function openMobileMenu() {
  $('mobile-nav').classList.add('open');
  $('mobile-nav').setAttribute('aria-hidden', 'false');
  $('mobile-nav-backdrop').classList.remove('hidden');
  $('menu-button').setAttribute('aria-expanded', 'true');
  document.body.classList.add('menu-open');
}

function closeMobileMenu() {
  $('mobile-nav').classList.remove('open');
  $('mobile-nav').setAttribute('aria-hidden', 'true');
  $('mobile-nav-backdrop').classList.add('hidden');
  $('menu-button').setAttribute('aria-expanded', 'false');
  document.body.classList.remove('menu-open');
}

// Navigation, filters and responsive controls ---------------------------------
window.addEventListener('hashchange', () => route().catch((error) => showToast(error.message, 'error')));
$('menu-button').addEventListener('click', openMobileMenu);
$('menu-close').addEventListener('click', closeMobileMenu);
$('mobile-nav-backdrop').addEventListener('click', closeMobileMenu);
$('search-toggle').addEventListener('click', () => {
  $('mobile-search-form').classList.toggle('open');
  if ($('mobile-search-form').classList.contains('open')) $('mobile-search-input').focus();
});
$('header-search-form').addEventListener('submit', (event) => { event.preventDefault(); submitGlobalSearch($('header-search-input')); });
$('mobile-search-form').addEventListener('submit', (event) => { event.preventDefault(); submitGlobalSearch($('mobile-search-input')); });
$('category-select').addEventListener('change', submitCatalogFilters);
let searchTimer;
$('search-input').addEventListener('input', () => {
  window.clearTimeout(searchTimer);
  searchTimer = window.setTimeout(submitCatalogFilters, 320);
});
$('checkout-button').addEventListener('click', checkout);
$('checkout-dialog-close').addEventListener('click', () => { $('checkout-dialog').close(); location.hash = '#shop'; });

// Authentication forms --------------------------------------------------------
$('login-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const message = $('login-message');
  setMessage(message, '');
  if (!validateForm(form, message)) return;
  const button = $('login-button');
  setButtonBusy(button, true, 'Signing in…');
  try {
    const auth = await api('/api/v1/auth/login', {
      method: 'POST', body: JSON.stringify({ email: $('login-email').value.trim(), password: $('login-password').value })
    });
    saveAuth(auth);
    await loadCart();
    form.reset();
    showToast(`Welcome back, ${auth.user.username}.`);
    location.hash = '#home';
  } catch (error) { setMessage(message, error.message); }
  finally { setButtonBusy(button, false); }
});

$('signup-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const message = $('signup-message');
  setMessage(message, '');
  const valid = validateForm(form, message, () => {
    if ($('signup-password').value !== $('signup-confirm-password').value) {
      $('signup-confirm-password').classList.add('invalid');
      setMessage(message, 'Passwords do not match.');
      $('signup-confirm-password').focus();
      return false;
    }
    return true;
  });
  if (!valid) return;
  const button = $('signup-button');
  setButtonBusy(button, true, 'Creating account…');
  try {
    const auth = await api('/api/v1/auth/signup', {
      method: 'POST', body: JSON.stringify({
        username: $('signup-username').value.trim(),
        email: $('signup-email').value.trim(),
        password: $('signup-password').value
      })
    });
    saveAuth(auth);
    await loadCart();
    form.reset();
    showToast('Your ShopSwift account is ready.');
    location.hash = '#home';
  } catch (error) { setMessage(message, error.message); }
  finally { setButtonBusy(button, false); }
});

// Profile and session actions --------------------------------------------------
$('profile-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const message = $('profile-message');
  setMessage(message, '');
  if (!validateForm(event.currentTarget, message)) return;
  const button = $('profile-button');
  setButtonBusy(button, true, 'Saving…');
  try {
    state.user = await api('/api/v1/profile', {
      method: 'PATCH', body: JSON.stringify({ username: $('profile-username').value.trim(), email: $('profile-email').value.trim() })
    });
    fillProfile();
    updateAccountNavigation();
    setMessage(message, 'Account information updated.', true);
  } catch (error) { setMessage(message, error.message); }
  finally { setButtonBusy(button, false); }
});

$('password-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const message = $('password-message');
  setMessage(message, '');
  if (!validateForm(form, message)) return;
  const button = $('password-button');
  setButtonBusy(button, true, 'Updating…');
  try {
    await api('/api/v1/profile/password', {
      method: 'PATCH', body: JSON.stringify({ currentPassword: $('current-password').value, newPassword: $('new-password').value })
    });
    form.reset();
    clearAuth();
    location.hash = '#login';
    setMessage($('login-message'), 'Password changed. Sign in again with your new password.', true);
  } catch (error) { setMessage(message, error.message); }
  finally { setButtonBusy(button, false); }
});

$('logout-button').addEventListener('click', async () => {
  try { await api('/api/v1/auth/logout', { method: 'POST' }); } catch (_) { /* local logout still completes */ }
  clearAuth();
  showToast('You have been signed out.');
  location.hash = '#home';
});

// PWA startup -----------------------------------------------------------------
async function start() {
  updateCartCount();
  updateAccountNavigation();
  await Promise.all([restoreSession(), loadInitialCatalog()]);
  await route();
}

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => navigator.serviceWorker.register('/sw.js').catch(() => {
    showToast('Offline support could not be enabled in this browser.', 'error');
  }));
}

start().catch((error) => showToast(error.message || 'ShopSwift could not start.', 'error'));
