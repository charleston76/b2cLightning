export const LOCAL_STORAGE_OBJECTS = {
    defaultFirstView: 'DefaultFirstView',
    categoryTree: 'CategoryTree',
    plpCategoryBannerContent: 'PLPCategoryBannerContent'    
}

export const SUPPORTED_FULLY_QUALIFIED_NAMES = {
    image: 'sfdc_cms__image',
    collection: 'sfdc_cms__cmsManualCollection'
}

export const IMG_SOURCE = {
    CMS: 'CMS',
    URL: 'URL'
}

export const BASE_IMAGE_PATH = '/sfsites/c'

export const BASE_IMAGE_MEDIA_PATH = '/sfsites/c/cms/delivery/media/'

export const MOBILE_INNERWIDTH = '600' 

export const PAGES_API_NAMES = {
    home: 'Home',
    cart: 'Current_Cart',
    myProfile: 'My_Account__c',
    register: 'Register',
    login: 'Login',
    wishlist: 'My_Wishlist_c__c',
    help:'Help__c'
}

export const CUSTOM_EVENTS_NAMES = {
    productVariantUpdate: 'product_variant_update',
    productQuantityUpdate: 'product_quantity_update',
    cartDrawerVisibility: 'cartdrawervisibility'
}

export const PRODUCT_CARD_CONFIGURATION = {
    "addToCartButtonText": "Añadir al carrito",
    "addToCartButtonProcessingText": "Agregando...",
    "showCallToActionButton": true,
    "viewOptionsButtonText": "Ver opciones",
    "showQuantitySelector": true,
    "minimumQuantityGuideText": "",
    "maximumQuantityGuideText": "",
    "incrementQuantityGuideText": "",
    "showQuantityRulesText": true,
    "quantitySelectorLabelText": "",
    "showProductImage": true,
    "addToCartDisabled": false,
    "layout": "grid",
    "fieldConfiguration": {
      "Name": {
        "fontSize": "medium",
        "showLabel": false
      }
    },
    "priceConfiguration": {
      "showNegotiatedPrice": true,
      "showListingPrice": true
    }
}

export const ALLOWABLE_COLORS = {
  blanco: "#f0f0f0",
  negro: "#000000",
  celeste: '#CCE5FF',
  azul: '#3333FF',
  naranja: '#FF8000',
  rosa: '#FF66FF',
  rojo: '#FF0000',
  verde_claro: '#33FF33',
  verde_oscuro: '#009900',
  marron: '#663300',
  amarillo: '#F7FF00' 
}

export const PRODUCT_CARD_BUTTON_OPTIONS = {
  addToCart: 'Añadir al carrito',
  viewOptions: 'Ver opciones'
}

export const DEFAULT_MIN_MAX_QUANTITY_SELECTOR = {
  min: 1,
  max: 1000000000
}

export const MAX_BANNER_IMAGES = 4