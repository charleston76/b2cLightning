import { LightningElement, api, track, wire } from 'lwc';
import { MOBILE_INNERWIDTH, BASE_IMAGE_MEDIA_PATH } from 'c/globalConstants';
import { ProductSearchAdapter , ProductCategoryAdapter } from 'commerce/productApi';
import getProductCategoryIdByName from '@salesforce/apex/ProductCategoryPicklist.getProductCategoryIdByName';
import siteId from "@salesforce/site/Id";

export default class B2bProductCarousel extends LightningElement {
    @track products = [];
    @track productCategory = {};
    
    @api searchParams;
    @api doSearch;
    
    @api categoryType;
    @api productCategoryName;
    @api showDetailImage;
    @api showPrices;
    @api sliderSpeed;
    @api itemsBySlideDesktop;
    @api itemsBySlideMobile;
    @api desktopHeight;
    @api desktopWidth;
    @api mobileHeight;
    @api mobileWidth;
    
    currentSlide = 0;
    autoSlideTimer;
    transitionDirection = 'next'; 

    get isMobile() {
        return window.innerWidth < MOBILE_INNERWIDTH;
    }

    get carouselStyle() {
        const itemsBySlide = this.isMobile ? this.itemsBySlideMobile : this.itemsBySlideDesktop;
        return `--items-by-slide: ${itemsBySlide};`;
    }

    get categoryTypeApiName() {
        switch (this.categoryType) {
            case 'Productos Destacados':
                return 'SOLUIsProductoDestacado__c';
            case 'Productos Nuevos':
                return 'SOLUIsProductoNuevo__c';
            case 'Nuestra Marca':
                return 'SOLUIsNuestraMarca__c';
            default:
                return 'Todos';
        }
    }

    connectedCallback() {
        this.updateItemsBySlide();
        window.addEventListener('resize', this.updateItemsBySlide.bind(this));
        this.startAutoSlide();
        this.loadCategoryId();
    }
    
    disconnectedCallback() {
        window.removeEventListener('resize', this.updateItemsBySlide.bind(this));
        this.stopAutoSlide();
    }

    updateItemsBySlide() {
        const itemsBySlide = this.isMobile ? this.itemsBySlideMobile : this.itemsBySlideDesktop;
        const carouselTrack = this.template.querySelector('.carousel-track');
        if (carouselTrack) {
            carouselTrack.style.setProperty('--items-by-slide', itemsBySlide);
        }
    }

    handlePrev() {
        if (this.currentSlide > 0) {
            const itemsBySlide = this.isMobile ? this.itemsBySlideMobile : this.itemsBySlideDesktop;
            const totalItems = this.products.length;
            this.currentSlide = (this.currentSlide - 1 + totalItems) % totalItems;
            this.transitionDirection = 'prev';
            this.updateCarousel();
            // this.restartAutoSlide();
        }
    }

    handleNext() {
        const itemsBySlide = this.isMobile ? this.itemsBySlideMobile : this.itemsBySlideDesktop;
        const totalItems = this.products.length;
        this.currentSlide = (this.currentSlide + 1) % totalItems;
        this.transitionDirection = 'next';
        this.updateCarousel();
        this.restartAutoSlide();
    }

    updateCarousel() {
        const track = this.template.querySelector('.carousel-track');
        const item = this.template.querySelector('.carousel-item');
        if (track && item) {
            const itemWidth = item.offsetWidth;
            const itemsBySlide = this.isMobile ? this.itemsBySlideMobile : this.itemsBySlideDesktop;
    
            track.style.transition = 'transform 0.6s ease-in-out';
            track.style.transform = `translateX(-${this.currentSlide * itemWidth}px)`;
    
            // Handle infinite scroll effect
            if (this.currentSlide === this.products.length - 1) {
                setTimeout(() => {
                    track.style.transition = 'none';
                    this.currentSlide = 0;
                    track.style.transform = `translateX(0px)`;
                }, 600);
            } else if (this.currentSlide === 0 && this.transitionDirection === 'prev') {
                setTimeout(() => {
                    track.style.transition = 'none';
                    this.currentSlide = this.products.length - 1;
                    track.style.transform = `translateX(-${this.currentSlide * itemWidth}px)`;
                }, 600);
            }
        }
    }
    

    startAutoSlide() {
        if (this.sliderSpeed !== 'Deactivated') {
            const interval = parseInt(this.sliderSpeed) * 1000;
            this.autoSlideTimer = setInterval(() => {
                this.handleNext();
            }, interval);
        }
    }

    stopAutoSlide() {
        if (this.autoSlideTimer) {
            clearInterval(this.autoSlideTimer);
            this.autoSlideTimer = null;
        }
    }

    restartAutoSlide() {
        this.stopAutoSlide();
        this.startAutoSlide();
    }
    
    async loadCategoryId() {
        try {
            // console.log('b2bProductCarousel loadCategoryId this.productCategoryName', this.productCategoryName);
            const categoryId = await getProductCategoryIdByName({ categoryName: this.productCategoryName });
            this.searchParams = {
                siteId: siteId,
                searchQuery: ' ',
                categoryId: categoryId,
                availability: 'inStock'
            };

            // console.log('b2bProductCarousel loadCategoryId this.searchParams', this.searchParams);
        } catch (error) {
            console.error('Error searching category Id:', error);
        }
    }

    @wire(ProductCategoryAdapter, { categoryId: '$searchParams.categoryId', siteId: siteId })
    wiredProductCategoryPath({ error, data }) {
        // console.log('b2bProductCarousel wiredProductCategoryPath this.searchParams', this.searchParams);
        // console.log('b2bProductCarousel wiredProductCategoryPath this.searchParams.categoryId', this.searchParams?.categoryId);
        if (this.searchParams && this.searchParams.categoryId){
            if (data) {
                this.productCategory = data;
                // console.log('>>> productCategory:', JSON.stringify(data, null, 2));
                this.checkDoSearch();
            } else if (error) {
                console.error('Error loading product category path:', JSON.stringify(error, null, 2));
            }
        }
    }

    @wire(ProductSearchAdapter, { searchQuery: '$searchParams' })
    wiredProducts({ error, data }) {
        // console.log('b2bProductCarousel wiredProducts this.searchParams', this.searchParams);
        // console.log('b2bProductCarousel wiredProducts this.searchParams.searchQuery', this.searchParams?.searchQuery);
        if (this.searchParams && this.searchParams.searchQuery) {
            //if have data and CategoryType selected is true on the category
            if (data && this.doSearch) {
                // console.log('>>> ProductSearchAdapter:', JSON.stringify(data, null, 2));
                if (data !== 'undefined' && data?.productsPage?.products !== 'undefined') {
                    let processedProducts = [];
                    data.productsPage.products.forEach(product => {
                        const imageUrl = product.defaultImage.url;
                        const contentIdMatch = imageUrl.match(/\/media\/([^?]+)/);
                        const contentId = contentIdMatch ? contentIdMatch[1] : '';

                        let processedProduct = {
                            Product_List_Image__c: BASE_IMAGE_MEDIA_PATH + contentId,
                            Product_Name__c: product.fields.Name.value,
                            Id: product.id,
                            Product_Detail_Images__c: [],
                            ListPrice: "",
                            UnitPrice: "" 
                        };
                        processedProducts.push(processedProduct);
                    });

                    //duplicate product if have small quantity
                    if (processedProducts.length <= 20) {
                        this.products = [...processedProducts, ...processedProducts];
                    } else {
                        this.products = processedProducts;
                    }
                }
            } else if (error){
                console.log('>>> ProductSearchAdapter error:', error);
            }
        }
    }

    checkDoSearch() {
        // console.log('b2bProductCarousel checkDoSearch this.categoryTypeApiName', this.categoryTypeApiName);
        const categoryField = this.categoryTypeApiName;
        // console.log('b2bProductCarousel checkDoSearch categoryField', categoryField);
        if (categoryField === 'Todos') {
            this.doSearch = true;
        } else {
            this.doSearch = this.productCategory.fields[categoryField] === 'true';
        }
        // console.log('b2bProductCarousel checkDoSearch this.doSearch', this.doSearch);
    }
}