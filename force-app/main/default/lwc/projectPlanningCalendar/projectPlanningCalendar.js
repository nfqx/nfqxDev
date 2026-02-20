import { LightningElement, track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import NFQXLOGO from '@salesforce/resourceUrl/NFQXLOGO';

import projectPlanning from '@salesforce/label/c.GeneralLabelProjectPlanning';
import changeTimeFrame from '@salesforce/label/c.GeneralLabelChangeTimeFrame';
import employeeMode from '@salesforce/label/c.GeneralLabelEmployeeMode';
import saveLabel from '@salesforce/label/c.Save';
import employee from '@salesforce/label/c.GeneralLabelEmployee';
import project from '@salesforce/label/c.GeneralLabelProject';
import calendarWeekAbbreviation from '@salesforce/label/c.GeneralLabelCalendarWeekAbbreviation';

import retrieveCalendarData from "@salesforce/apex/ProjectPlanningController.retrieveCalendarData";
import retrieveCurrentWeeks from "@salesforce/apex/ProjectPlanningController.retrieveCurrentWeeks";

export default class ProjectPlanningCalendar extends NavigationMixin(LightningElement) {
    get nfqxLogoUrl() {
        return NFQXLOGO;
    }

    label = {
        projectPlanning,
        changeTimeFrame,
        employeeMode,
        saveLabel,
        employee,
        project,
        calendarWeekAbbreviation
    };

    @track dataLoaded = false;
    @track hasData = false;
    @track selectedWeeks = [];
    @track projectEmployeeData = [];

    @track showModal = false;
    @track selectedPlanningForModal = null;

    connectedCallback(){
        retrieveCurrentWeeks()
        .then(result => {
            this.selectedWeeks = JSON.parse(JSON.stringify(result));
            retrieveCalendarData({weeks: this.selectedWeeks})
            .then(innerResult => {
                this.projectEmployeeData = JSON.parse(JSON.stringify(innerResult));
                this.dataLoaded = true;
                this.hasData = this.projectEmployeeData.length > 0;
            })
        });
    }

    switchToEmployeeOverview(){
        this[NavigationMixin.Navigate]({
            type: "standard__navItemPage",
            attributes: {
                apiName: "ProjectPlanningEmployeeOverview",
            },
        });
    }

    handleSaveRecord(){

    }

    handleOpenCalendar(){
        
    }
}