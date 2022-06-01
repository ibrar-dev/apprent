import axios from 'axios';

export default {
    likeComment(params) {
        return axios.patch('/social', {params});
    },
    blockUser(block) {
        return axios.post('/social', {block});
    },
    reportPost(report) {
        return axios.post('/social', {report});
    },
    deletePost(id){
        return axios.delete(`/social/${id.post_id}`);
    }
};