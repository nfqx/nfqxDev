import { LightningElement, track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import NFQXLOGO from '@salesforce/resourceUrl/NFQXLOGO';

import employeesOverview from '@salesforce/label/c.GeneralLabelEmployeesOverview';
import changeTimeFrame from '@salesforce/label/c.GeneralLabelChangeTimeFrame';
import employee from '@salesforce/label/c.GeneralLabelEmployee';
import project from '@salesforce/label/c.GeneralLabelProject';
import projectMode from '@salesforce/label/c.GeneralLabelProjectMode';
import calendarWeekAbbreviation from '@salesforce/label/c.GeneralLabelCalendarWeekAbbreviation';

import retrieveEmployeeData from "@salesforce/apex/ProjectPlanningController.retrieveEmployeeData";
import retrieveCurrentWeeks from "@salesforce/apex/ProjectPlanningController.retrieveCurrentWeeks";

export default class ProjectPlanningEmployeeOverview extends NavigationMixin(LightningElement) {
    get nfqxLogoUrl() {
        return NFQXLOGO;
    }

    label = {
        employeesOverview,
        changeTimeFrame,
        employee,
        project,
        projectMode,
        calendarWeekAbbreviation
    };

    @track dataLoaded = false;
    @track hasData = false;
    @track selectedWeeks = [];
    @track employeeProjectData = [];

    connectedCallback(){
        retrieveCurrentWeeks()
        .then(result => {
            this.selectedWeeks = JSON.parse(JSON.stringify(result));
            retrieveEmployeeData({weeks: this.selectedWeeks})
            .then(innerResult => {
                this.employeeProjectData = JSON.parse(JSON.stringify(innerResult));
                this.dataLoaded = true;
                this.hasData = this.employeeProjectData.length > 0;
            })
        });
    }

    switchToPlanningCalendar(){
        this[NavigationMixin.Navigate]({
            type: "standard__navItemPage",
            attributes: {
                apiName: "ProjectPlanningCalendar",
            },
        });
    }

    handleOpenCalendar(){
        
    }
}