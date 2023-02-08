import { LightningElement, track } from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';

export default class EmpApiLWC extends LightningElement {
    //This is the event you created in Setup > Platform Events
    channelName = '/event/Checkout_Intermediate_Notification__e';
    subscription = {};
    @track _checkoutsInProgress = [];

    constructor() {
        super();
        this.handleSubscribe();
    }

    connectedCallback() {
        this.registerErrorListener();
    }

    handleSubscribe() {
        // Callback invoked whenever a new event message is received
        console.log('EmpApiLWC handleSubscribe in')
        const messageCallback = (response) => {
            this.payload = JSON.stringify(response);
            console.log('EmpApiLWC handleSubscribe messageCallback this.payload ', this.payload)
            if (this.payload != null) this._checkoutsInProgress.push(JSON.parse(this.payload));
        };

        // Invoke subscribe method of empApi passing the reference to messageCallback
        subscribe(this.channelName, -1, messageCallback()).then(response => {
            console.log('EmpApiLWC handleSubscribe subscribe');
            console.log('Subscription request sent to event: ', JSON.stringify(response.channel));
            this.subscription = response;
            console.log('Subscribe done.');
        });

        
    }

    registerErrorListener() {
        onError(error => {
            console.log('Received error from server: ', JSON.stringify(error));
        });
    }
}