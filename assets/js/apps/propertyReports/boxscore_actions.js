const actions = {
    noticeUnrented(units, used){
        const noticeUnrented = [];
        // const used = this.state.usedArray;
        units.forEach(u => {
            const lease = u.lease;
            if (lease && lease.notice_date && !lease.actual_move_out && !used.includes(u.id)) {
                used.push(u.id);
                noticeUnrented.push(u);
            }

        });
        return noticeUnrented;
    },
    noticeRented(units, used) {
        // const used = this.state.usedArray;
        let noticeRented = [];
        units.forEach(u => {
            const lease = u.lease;
            if(lease && lease.notice_date && !lease.actual_move_out && lease.move_in.length && !used.includes(u.id)){
                used.push(u.id);
                noticeRented.push(u);
            }
            // if (u.prev_lease.notice_date && !lease.actual_move_in && !used.includes(u.id)) {
            //     used.push(u.id);
            //     noticeRented.push(u);
            // }
        });
        return noticeRented;
    },
    vacantUnrented(units, used) {
        const vacantUnrented = [];
        // const used = this.state.usedArray;
        units.forEach(u => {
            if(used.includes(u.id)) return;
            const lease = u.lease;
            if(!lease.id){
                vacantUnrented.push(u);
                used.push(u.id);
            // }else if(lease.actual_move_out && lease.move_out_date){
            //     vacantUnrented.push(u);
            //     used.push(u.id);
            }
        });
        return vacantUnrented;
    },
    vacantRented(units, used){
        const vacantRented = [];
        // const used = this.state.usedArray;
        units.forEach( u => {
            if(used.includes(u.id)) return;
            const lease = u.lease;
            if(!u.prev_lease.id || u.prev_lease.actual_move_out){
                if(!lease.actual_move_in) {
                    used.push(u.id)
                    vacantRented.push(u)
                }
            }
        });
        return vacantRented;
    },
    down(units, used){
        const down = [];
        // const used = this.state.usedArray;
        units.forEach( u => {
            if(used.includes(u.id)) return;
            if(u.status === "DOWN"){
                used.push(u.id)
                down.push(u);
            }
        });
        return down;
    },
    reno(units, used){
        const reno = [];
        units.forEach(u => {
            if(u.status === "RENO") reno.push(u);
        })
        return reno;
    },
    // avail(units, used){
    //   const avail = [];
    //   units.forEach( u => {
    //       if(used.includes(u.id)) return;
    //       const lease = u.lease;
    //       if(!u.lease.id){
    //           used.push(u.id)
    //           avail.push(u)
    //       }
    //   })
    //   return avail;
    // },
    occupied(units, used){
      const occ = [];
      units.forEach( u => {
          if(used.includes(u.id)) return;
          const lease = u.lease;
          if(lease.actual_move_in || lease.is_renewal){
              used.push(u.id)
              occ.push(u)
          }
      })
      return occ;
    }
}

export default actions;