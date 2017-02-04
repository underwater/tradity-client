import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

import { SharedModule } from '../shared/shared.module';

import { RankingComponent }   from './ranking.component';
import { AlltimeRankingComponent } from './alltime-ranking.component';
import { WeeklyRankingComponent } from './weekly-ranking.component';
import { GroupsRankingComponent } from './groups-ranking.component';

@NgModule({
  imports: [
    CommonModule,
    SharedModule,
    RouterModule
  ],
  exports: [],
  declarations: [
    RankingComponent,
    AlltimeRankingComponent,
    WeeklyRankingComponent,
    GroupsRankingComponent
  ],
  providers: [],
})
export class RankingModule { }
