import { LightningElement, api, wire, track } from 'lwc';
import { MOBILE_INNERWIDTH, BASE_IMAGE_MEDIA_PATH } from 'c/globalConstants';
import { ProductAdapter, ProductPricingAdapter } from 'commerce/productApi';
import { NavigationMixin } from 'lightning/navigation';
import effectiveAccountId from '@salesforce/user/Id';

export default class B2bProductCarouselItem extends NavigationMixin(LightningElement) {
    @api product;
    @api showDetailImage;
    @api showPrices;
    @api desktopWidth;
    @api desktopHeight;
    @api mobileHeight;
    @api mobileWidth;

    @track productDetails = {};
    @track productPrices = {};

    //Just allow 37 characters
    get truncatedProductName() {
        const name = this.product.Product_Name__c;
        return name.length > 37 ? `${name.substring(0, 35)}...` : name;
    }

    //Just allow 3 image detail per product
    get truncatedDetailImages() {
        if (!this.productDetails.Product_Detail_Images__c) {
            return [];
        }
        return this.productDetails.Product_Detail_Images__c.slice(0, 3);
    }

    get cardStyle() {
        const componentWidth = this.isMobile ? this.mobileWidth : this.desktopWidth;
        const componentHeight = this.isMobile ? this.mobileHeight : this.desktopHeight;

        return `width: ${componentWidth}; height: ${componentHeight};`;
    }

    get isMobile() {
        return window.innerWidth < MOBILE_INNERWIDTH;
    }

    @wire(ProductAdapter, { productId: '$product.Id' })
    wiredProductDetails({ error, data }) {
        if (data) {
            const detailImages = data.mediaGroups
                .find(group => group.developerName === 'productDetailImage')?.mediaItems.map(item => {
                    const contentIdMatch = item.url.match(/\/media\/([^?]+)/);
                    const contentId = contentIdMatch ? contentIdMatch[1] : '';
                    return `${BASE_IMAGE_MEDIA_PATH}${contentId}`;
                }) || [];
                
            const product = {
                ...this.product,
                Product_Detail_Images__c: detailImages,
                ListPrice: data.fields?.ListPrice || '',
                UnitPrice: data.fields?.UnitPrice || ''
            };
            this.productDetails = product;
            // console.log('>>> this.productDetails: '+JSON.stringify(this.productDetails, null, 2));
        } else if (error) {
            console.error('Error loading product details:', error);
        }
    }

    @wire(ProductPricingAdapter, { effectiveAccountId: '$effectiveAccountId', productId: '$product.Id' })
    wiredProductPricing({ error, data }) {

        if(data){
            // console.log('>>> ProductPricingAdapter: '+JSON.stringify(data, null, 2));
            if (this.showPrices) {
                let listPrice = '$'+data.unitPrice || '';
                let unitPrice = '$'+data.negotiatedPrice || '$'+listPrice;
                if (listPrice && unitPrice && listPrice !== unitPrice) {
                    this.productPrices = {
                        ListPrice: listPrice,
                        UnitPrice: unitPrice
                    };
                } else {
                    this.productPrices = {
                        ListPrice: '',
                        UnitPrice: unitPrice
                    };
                }                
            }
        } else if(error){
            console.log('>>> pricing erro: '+JSON.stringify(error, null,2));
        }
    }
    
    handleClick() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.product.Id,
                objectApiName: 'Product2',
                actionName: 'view'
            }
        });
    }
}